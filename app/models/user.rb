class User < ActiveRecord::Base
  has_many :friendships
  has_many :friends, :through => :friendships
  has_many :inverse_friendships, :class_name => "Friendship", :foreign_key => "friend_id"
  has_many :inverse_friends, :through => :inverse_friendships, :source => :user
  has_and_belongs_to_many :groups
  scope :male, where("gender = ?", "male")
  scope :female, where("gender = ?", "female")

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

  def self.create_with_omniauth_and_add_friends(auth)
    begin_time = Time.now
    user = User.create_with_omniauth(auth)
    current_friends_uids = user.all_friends.collect { |friend| friend.uid }
    fbquery = "SELECT uid, name, sex, current_location FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 =#{auth["uid"]})"
    friends = FbGraph::Query.new(fbquery).fetch(auth["credentials"]["token"]) #this might take a while...
    filtered_friends = friends.reject{ |fq| current_friends_uids.index(fq["uid"].to_s) }

    Crewait.start_waiting
    filtered_friends.each do |fq|
      friend = User.crewait(:uid => fq["uid"].to_s, :name => fq["name"], :gender => fq["sex"])
      Friendship.crewait(:user_id => user.id, :friend_id => friend.id)
    end
    Crewait.go!
    #raise "create with omniauth and add friends took #{(Time.now - begin_time)*1000}ms"
    return user
  end

  def random_match(gender = nil, group = nil)
    #specify opposite gender
    if !gender
      gender = "female"
      gender = "male" if self.gender == "female"
    end

    if group
      group.users.find(:all, :conditions => ["gender = ? AND NOT id = ?", gender, self.id], :limit => 2,  :order => "RANDOM()")
    else
      # OLD RANDOM      self.friends.find(:all, :conditions => ["gender = ?", gender], :limit => 2, :order => "RANDOM()")
      size = self.friends.where(:gender => gender).size 
      self.friends.where(:gender => gender).offset(rand(size)).order("RANDOM()").limit(2) [0..1]
    end
  end




  def self.update_scores_by_uid(uids, choice) #ELO Rating system.
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

  def update_groups(auth)
    #fq = FbGraph::Query.new("SELECT work_history,education_history,current_location FROM user where uid=#{auth["uid"]}").fetch(auth["credentials"]["token"])
    hash = auth['extra']['user_hash']
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
    "#{self.win}/#{self.win + self.loss}"
  end
end
