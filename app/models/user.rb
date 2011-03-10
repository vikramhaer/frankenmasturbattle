class User < ActiveRecord::Base
  has_many :friendships
  has_many :friends, :through => :friendships
  has_many :inverse_friendships, :class_name => "Friendship", :foreign_key => "friend_id"
  has_many :inverse_friends, :through => :inverse_friendships, :source => :user
  has_and_belongs_to_many :groups
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

  def update_friends(auth)
    fbquery = "SELECT uid, name, sex, current_location FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 =#{auth["uid"]})"
    fbq_friends = FbGraph::Query.new(fbquery).fetch(auth["credentials"]["token"]) #this might take a while...
    fbq_friends_uids = fbq_friends.collect { |fbq_friend| fbq_friend["uid"].to_s }
    begin_time = Time.now
    users_from_fbq = User.where(:uid => fbq_friends_uids )
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
  end

  def add_friends(auth)
    fbquery = "SELECT uid, name, sex, current_location FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 =#{auth["uid"]})"
    fb_friends = FbGraph::Query.new(fbquery).fetch(auth["credentials"]["token"]) #this might take a while...
    begin_time = Time.now
    friends_who_friended_you = self.all_friends.collect { |friend| friend.uid }
    friends_in_the_database = User.where(:uid => fb_friends.collect{ |fq| fq["uid"].to_s }) #User objects who have uids matching one in the fbquery
    uids_of_friends_in_the_database = friends_in_the_database.collect { |friend| friend.uid }

    friends_not_in_the_database = fb_friends.reject{ |fq| uids_of_friends_in_the_database.index(fq["uid"].to_s) } #fq objects which aren't in the db

    friends_who_have_not_friended_you = friends_in_the_database.reject{ |friend| friends_who_friended_you.index(friend.uid) } #User objects in the db who don't have you as a friend
    new_friend_ids = []
    raise "create with omniauth and add friends took #{(Time.now - begin_time)*1000}ms"
    Crewait.start_waiting
    friends_not_in_the_database.each do |fq|
      friend = User.crewait(:uid => fq["uid"].to_s, :name => fq["name"], :gender => fq["sex"])
      new_friend_ids << [friend.id, fq]
      Friendship.crewait(:user_id => self.id, :friend_id => friend.id)
    end
    friends_in_the_database.each do |friend|
      Friendship.crewait(:user_id => self.id, :friend_id => friend.id)
    end
    Crewait.go!

    #new_friend_ids.collect{ |arr| [User.find_by_id(arr[0].to_i), arr[1]] }.each do |arr|
    #  arr[0].update_groups_with_fq(arr[1]) if arr[0]
    #end
    return self
  end

  def random_match(options)
    gender = options["gender"] || "female"
    networkid = (options["network"] || "0").to_i

    if networkid == 0 #only friends selected
      size = self.friends.where(:gender => gender).size
      pool = self.friends.where(:gender => gender)
    else
      network = self.groups.find_by_id(networkid)
      size = network.users.where(:gender => gender).size
      pool = network.users.where(:gender => gender).where("uid != ?", self.uid)
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
    return [user0, user1, dscore]
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

    if hash['location']
      loc_group = Group.find_by_gid(hash['location']['id'].to_s)
      if loc_group
        self.groups << loc_group if !self.groups.exists?(loc_group)
      else
        self.groups.create(:name => hash['location']['name'], :gid => hash['location']['id'].to_s, :type => 'loc') 
      end
    end

    if hash['work']
      hash['work'].each do |job|
        job_group = Group.find_by_gid(job['employer']['id'].to_s)
        if job_group
          self.groups << job_group if !self.groups.exists?(job_group)
        else
          self.groups.create(:name => job['employer']['name'], :gid => job['employer']['id'].to_s, :type => 'job')
        end
      end
    end
    
    if hash['education']
      hash['education'].each do |edu|
        edu_group = Group.find_by_gid(edu['school']['id'].to_s)
        if edu_group
          self.groups << edu_group if !self.groups.exists?(edu_group)
        else
          self.groups.create(:name => edu['school']['name'], :gid => edu['school']['id'].to_s, :type => 'edu')   
        end
      end
    end
  end

  def update_groups_with_fq(fq) #Using Crewait!!! 
    if fq['current_location']
      loc_group = Group.find_by_gid(fq['current_location']['id'].to_s)
      if loc_group
        self.groups << loc_group if !self.groups.exists?(loc_group)
      else
        self.groups.create(:name => fq['current_location']['name'], :gid => fq['current_location']['id'].to_s, :type => 'loc')
      end
    end
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
