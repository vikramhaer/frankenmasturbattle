class User < ActiveRecord::Base
  has_many :friendships, :dependent => :destroy
  has_many :friends, :through => :friendships
  has_many :inverse_friendships, :class_name => "Friendship", :foreign_key => "friend_id", :dependent => :destroy
  has_many :inverse_friends, :through => :inverse_friendships, :source => :user
  has_many :memberships, :dependent => :destroy
  has_many :groups, :through => :memberships

  scope :male, where("gender = ?", "male")
  scope :female, where("gender = ?", "female")
  scope :top25, order("score desc").limit(25)
  scope :top5, order("score desc").limit(5)
  scope :unrated, where("win = ? AND loss = ?", 0, 0)
  scope :active, where("settings != ?", 0)

  def increment_login_count
    lg = self.login_count + 1
    self.update_attributes(:login_count => lg.to_i)
  end

  def increment_rating_count
    rt = self.rating_count + 1
    self.update_attributes(:rating_count => rt.to_i)
  end

  #postponed more complex settings until later...
  #def settings_to_array
  #  self.settings.to_s(16).split("").collect{|str| str.to_i(16)}
  #end

  def all_friends
    self.friends | self.inverse_friends  
  end

  def all_friends_order_by_score_desc_limit(limit)
    list = self.friends.order("score desc").limit(limit) | self.inverse_friends.order("score desc").limit(limit)
    list.sort! { |b,a| a.score <=> b.score }
    list[0..limit-1]
  end

  def self.create_with_omniauth(auth)
    create! do |user|
      user.uid = auth["uid"].to_s
      user.name = auth["user_info"]["name"]
      user.gender = auth["extra"]["user_hash"]["gender"]
    end
  end

  def login_procedure(auth)

  end

  def standard_login(auth)
    self.update_info(auth)
    self.update_groups(auth)
    self.increment_login_count
  end

  def first_login(token)
    self.update_friends(self.uid, token)
    if self.score < 1000 then self.update_attributes(:score => 1000) end
  end

  def update_info(auth)
    new_name = auth["user_info"]["name"]
    new_gender = auth["extra"]["user_hash"]["gender"]
    new_email = auth['extra']['user_hash']['email']
    self.update_attributes({:email => new_email}) if self.email != new_email
    self.update_attributes({:gender => new_gender}) if self.gender != new_gender
    self.update_attributes({:name => new_name}) if self.name != new_name
  end

  def update_groups(auth)
    hash = auth['extra']['user_hash']
    all_groups = self.groups
    location = hash['location']
    if location
      name_formatted = location['name'].each { |word| word.capitalize! }
      loc_group = Group.find_by_name(name_formatted) || self.groups.create(:name => name_formatted, :gid => location['id'].to_s, :type => 'loc') 
      self.groups << loc_group if !self.groups.exists?(loc_group)
    end

    if hash['education']
      hash['education'].each do |edu|
        school = edu['school']
        name_formatted = school['name'].each { |word| word.capitalize! }
        edu_group = Group.find_by_name(name_formatted) || Group.create(:name => name_formatted, :gid => school['id'].to_s, :type => 'edu')
        self.groups << edu_group if !self.groups.exists?(edu_group)
      end
    end
  end

  def update_friends(uid, token)
    #a = Time.now
    fbquery = "SELECT uid, name, sex, current_location, education_history, hs_info FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 =#{uid})"
    fbq_friends = FbGraph::Query.new(fbquery).fetch(token) #this might take a while...
    #b = Time.now
    users_from_fbq = User.where(:uid => fbq_friends.collect { |fbq_friend| fbq_friend["uid"].to_s } )
    hashed_users_from_fbq = Hash[ users_from_fbq.collect { |user| [user.uid, user] } ]

    friends_not_added = users_from_fbq - self.friends
    friends_not_created = fbq_friends.reject{ |fbq_friend| hashed_users_from_fbq.include?(fbq_friend["uid"].to_s) }
    

    #add groups for all the new people
    groups_not_created = []
    if !friends_not_created.empty?
      #get all the groups of the friends not created yet
      friends_not_created_groups = friends_not_created.collect{ |fq| helper_get_group_names_from_fq(fq) }.flatten!.reject{|g| g == nil}.uniq!
      #find all the groups already in the db
      groups_from_fbq = Group.where(:name => friends_not_created_groups)
      #hash them for fast lookup later
      hashed_groups_from_fbq = Hash[ groups_from_fbq.collect { |group| [group.name, group.id] } ]
      #figure out which were not created yet by comparing the original list with the results from db
      groups_not_created = friends_not_created_groups.reject {|group_name| hashed_groups_from_fbq.include?(group_name) }
    end

    #c = Time.now

    #raise ((b-a)*1000).to_s + " " + ((c-b)*1000).to_s #+ friends_not_created_groups.to_yaml
    if !friends_not_added.empty? or !friends_not_created.empty? or !groups_not_created.empty?
      Crewait.start_waiting
      groups_not_created.each do |group_name|
        #create each group
        group = Group.crewait(:name => group_name)
        #add each group to the hash to add memberships later on
        hashed_groups_from_fbq[group_name] = group.id+1 #NEED +1 PATCH B/C CREWAIT's OFFBY1 ERROR.
      end
      friends_not_added.each do |friend|
        Friendship.crewait(:user_id => self.id, :friend_id => friend.id ) #these are existing users so not affected by offby1
      end
      statlist = []
      friends_not_created.each do |fbq_friend|
        #create the friend
        friend = User.crewait(:uid => fbq_friend["uid"].to_s, :name => fbq_friend["name"], :gender => fbq_friend["sex"])
        #add the friendship
        Friendship.crewait(:user_id => self.id, :friend_id => (friend.id+1) ) #NEED +1 PATCH B/C CREWAIT's OFFBY1 ERROR.
        #find the friend's groups
        groups_to_join = helper_get_group_names_from_fq(fbq_friend).uniq.reject{|g| g == nil}
        statlist << (fbq_friend["name"] + "[" + (friend.id+1).to_s + "]:" + groups_to_join.collect{|group_name| group_name + "[" + hashed_groups_from_fbq[group_name].to_s + "]"} * ",")
        groups_to_join.each do |group_name|
          #add memberships for each group
          Membership.crewait(:user_id => (friend.id+1), :group_id => hashed_groups_from_fbq[group_name] ) #NEED +1 PATCH B/C CREWAIT's OFFBY1 ERROR.
        end
      end
      #raise statlist.to_yaml
      Crewait.go!
    end
    #d = Time.now
    #insert group insertion code here
    #friends_not_created.each do |fbq_friend|         #THIS IS SLOWWWWWW
    #  user = User.where(:uid => fbq_friend["uid"].to_s).first
    #  user.update_groups_with_fq(fbq_friend)
    #end
    #raise "fbquery = #{(b-a)*1000}ms, sorting_and_call = #{(c-b)*1000}ms, insertion= #{(d-c)*1000}ms"
    #raise "update_friends took #{(Time.now - begin_time)*1000} ms"
  end

  def helper_get_group_names_from_fq(fq)
    rtn = []
    rtn << fq['current_location']['name'] if fq['current_location']

    if fq['education_history']
      fq['education_history'].each do |edu|
        name_formatted = edu['name'].each { |word| word.capitalize! }
        rtn << name_formatted
      end
    end
    
    if fq['hs_info']
      if fq['hs_info']['hs1_name'] && fq['hs_info']['hs1_name'] != ""
        name_formatted = fq['hs_info']['hs1_name'].each { |word| word.capitalize! }
        rtn << name_formatted
      end
      if fq['hs_info']['hs2_name'] && fq['hs_info']['hs2_name'] != ""
        name_formatted = fq['hs_info']['hs2_name'].each { |word| word.capitalize! }
        rtn << name_formatted
      end
    end

    return rtn
  end
    

  def update_groups_with_fq(fq) #Only has location atm, need to add education!
    if fq['current_location']
      loc = fq['current_location']
      loc_group = Group.find_by_gid(loc['id'].to_s) || Group.create!(:name => loc['name'], :gid => loc['id'].to_s, :type => 'loc')
      self.groups << loc_group if !self.groups.exists?(loc_group)
    end
    #raise fq.to_yaml if fq["uid"] == "1091640001"
    if fq['education_history']
      fq['education_history'].each do |edu|
        name_formatted = edu['name'].each { |word| word.capitalize! }
        edu_group = Group.find_by_name( name_formatted ) || Group.create!(:name => name_formatted, :gid => "0", :type => 'edu')
        self.groups << edu_group if !self.groups.exists?(edu_group)
      end
    end
  end

  def force_group_update(token)
    fbquery = "SELECT uid, name, sex, current_location, education_history FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 =#{self.uid})"
    fbq_friends = FbGraph::Query.new(fbquery).fetch(token) #this might take a while...
    fbq_friends.each do |fbq_friend|         #THIS IS SLOWWWWWW
      user = User.where(:uid => fbq_friend["uid"].to_s).first
      user.update_groups_with_fq(fbq_friend)
    end
  end

  def random_match(options)
    a = Time.now
    gender = options["gender"] || "female"
    networkid = (options["network"] || "0").to_i

    if networkid == 0 #only friends selected
      @friends = self.friends.where(:gender => gender).active
      size = @friends.length
      pool = @friends
      #size = self.friends.where(:gender => gender).active.size
      #pool = self.friends.where(:gender => gender).active.order("id asc")
    else
      @network_users = self.groups.find_by_id(networkid).users.where(:gender => gender).active
      size = @network_users.length
      pool = @network_users
    end
    b = Time.now
    if size < 10 then 
      return [nil, nil]
    else
      results = []
      cap = ([(size-1)/2*2, 30].min) -1
      (0..size-1).sort_by{rand}[0..cap].each do |offset|
        results << pool[offset]
      end
      c = Time.now
      return results.collect{ |user| {"name" => user.name, "uid" => user.uid} }
    end
  end   

  def self.update_scores_by_uid(uids, choice) #ELO Rating system.
    return [nil,nil] if uids == [nil,nil]
    def add_win(dscore)
      self.update_attributes({:score => self.score + dscore, :win => self.win + 1})
    end

    def add_loss(dscore)
      self.update_attributes({:score => self.score - dscore, :loss => self.loss + 1})
    end
  
    user0 = User.find_by_uid(uids[0])
    user1 = User.find_by_uid(uids[1])
    if !user0 or !user1 then return -1 end

    k = 25
    winp = 1/(10 ** ((user1.score - user0.score)/400.0) + 1)
    dscore = (k * (1 - winp))

    if choice == "left" then
      user0.add_win(dscore)
      user1.add_loss(dscore)
    elsif choice == "right" then
      user1.add_win(dscore)
      user0.add_loss(dscore)
    else
      return -1
    end
    return [user0, user1, choice]
  end

  #pretty formatting stuff for the views
  def win_loss
    "Wins: #{self.win} Losses: #{self.loss}"
  end

  def is_female?
    self.gender == "female"
  end

  def is_male?          #assume user is male if not specified (view girls by default)
    !self.is_female?
  end

  def opposite_gender
    if self.is_male?
      "female"
    else
      "male"
    end
  end

  def is_inactive?
    self.settings == 0
  end

  def is_new?
    self.login_count == 0
  end
end
