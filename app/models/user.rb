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

  def increment_login_count
    lg = self.login_count + 1
    self.update_attributes(:login_count => lg.to_i)
  end

  def increment_rating_count
    rt = self.rating_count + 1
    self.update_attributes(:rating_count => rt.to_i)
  end

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
    if self.login_count == 0
      if self.score < 1000 then self.update_attributes(:score => 1000) end
    end
    self.increment_login_count
    self.update_info(auth)
    self.update_groups(auth)
    self.update_friends(auth)
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
    #fq = FbGraph::Query.new("SELECT work_history,education_history,current_location FROM user where uid=#{auth["uid"]}").fetch(auth["credentials"]["token"])
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

  def update_friends(auth)
    fbquery = "SELECT uid, name, sex, current_location, education_history FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 =#{auth["uid"]})"
    fbq_friends = FbGraph::Query.new(fbquery).fetch(auth["credentials"]["token"]) #this might take a while...
    begin_time = Time.now
    users_from_fbq = User.where(:uid => fbq_friends.collect { |fbq_friend| fbq_friend["uid"].to_s } )
    hashed_users_from_fbq = Hash[ users_from_fbq.collect { |user| [user.uid, user] } ]

    friends_not_added = users_from_fbq - self.friends
    friends_not_created = fbq_friends.reject{ |fbq_friend| hashed_users_from_fbq.include?(fbq_friend["uid"].to_s) }  
    
    if !friends_not_added.empty? or !friends_not_created.empty?
      Crewait.start_waiting
      friends_not_added.each do |friend|
        Friendship.crewait(:user_id => self.id, :friend_id => friend.id)
      end

      friends_not_created.each do |fbq_friend|
        friend = User.crewait(:uid => fbq_friend["uid"].to_s, :name => fbq_friend["name"], :gender => fbq_friend["sex"])
        Friendship.crewait(:user_id => self.id, :friend_id => friend.id)
      end    
      Crewait.go!
    end

    #insert group insertion code here
    friends_not_created.each do |fbq_friend|         #THIS IS SLOWWWWWW
      user = User.where(:uid => fbq_friend["uid"].to_s).first
      user.update_groups_with_fq(fbq_friend)
    end
    #raise "update_friends took #{(Time.now - begin_time)*1000} ms"
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
    gender = options["gender"] || "female"
    networkid = (options["network"] || "0").to_i

    if networkid == 0 #only friends selected
      size = self.friends.where(:gender => gender).size
      pool = self.friends.where(:gender => gender).order("id asc")
    else
      network = self.groups.find_by_id(networkid)
      size = network.users.where(:gender => gender).size
      pool = network.users.where(:gender => gender).where("uid != ?", self.uid).order("id asc")
    end

    if size < 10 then 
      return [nil, nil]
    else
      results = []
      cap = ([(size-1)/2*2, 30].min) -1
      (0..size-1).sort_by{rand}[0..cap].each do |offset|
        results << pool.offset(offset).limit(1)
      end
      return results.collect{ |user| {"name" => user[0].name, "uid" => user[0].uid} }
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
end
