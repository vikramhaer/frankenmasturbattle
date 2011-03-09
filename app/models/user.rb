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
      self.add_friends(auth)
    end
    self.update_info(auth)
    self.update_groups(auth)
    self.increment_login_count
  end

  def add_friends(auth)
    friends_who_friended_you = self.all_friends.collect { |friend| friend.uid }
    fbquery = "SELECT uid, name, sex, current_location FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 =#{auth["uid"]})"
    fb_friends = FbGraph::Query.new(fbquery).fetch(auth["credentials"]["token"]) #this might take a while...

    friends_in_the_database = User.where(:uid => fb_friends.collect{ |fq| fq["uid"].to_s }) #User objects who have uids matching one in the fbquery
    uids_of_friends_in_the_database = friends_in_the_database.collect { |friend| friend.uid }

    friends_not_in_the_database = fb_friends.reject{ |fq| uids_of_friends_in_the_database.index(fq["uid"].to_s) } #fq objects which aren't in the db

    friends_who_have_not_friended_you = friends_in_the_database.reject{ |friend| friends_who_friended_you.index(friend.uid) } #User objects in the db who don't have you as a friend

    Crewait.start_waiting
    friends_not_in_the_database.each do |fq|
      friend = User.crewait(:uid => fq["uid"].to_s, :name => fq["name"], :gender => fq["sex"])
      Friendship.crewait(:user_id => self.id, :friend_id => friend.id)
    end
    friends_who_have_not_friended_you.each do |friend|
      Friendship.crewait(:user_id => self.id, :friend_id => friend.id)
    end

    Crewait.go!
    #raise "create with omniauth and add friends took #{(Time.now - begin_time)*1000}ms"
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
  
    #perform lookup since score cannot be guaranteed
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

  def update_groups_with_fql(fq) #moving to not use fql because it doesn't give ids so gonna be deprecated.
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
