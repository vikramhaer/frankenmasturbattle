class User < ActiveRecord::Base
  has_many :friendships
  has_many :friends, :through => :friendships
  has_many :inverse_friendships, :class_name => "Friendship", :foreign_key => "friend_id"
  has_many :inverse_friends, :through => :inverse_friendships, :source => :user
  has_and_belongs_to_many :groups

  def all_friends
    self.friends + self.inverse_friends
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
    #filtered_friends.chunk(50).each do |batch|
    user_batch_import = []
    friendship_batch_import = []
    filtered_friends.each do |fq|
      #user_batch_import << User.new(:uid => fq["uid"].to_s, :name => fq["name"], :gender => fq["sex"])
      friend = User.create!(:uid => fq["uid"].to_s, :name => fq["name"], :gender => fq["sex"])
      friendship_batch_import << Friendship.new(:user_id => user.id, :friend_id => friend.id)
    end
    #User.import user_batch_import
    Friendship.import friendship_batch_import

    #raise (user.all_friends.collect{ | friend| friend.uid} - current_friends_uids).to_yaml
    #friendship_batch_import = []
    #all_friends_plus_new = user.all_friends
    #new_friends = all_friends_plus_new.reject{ |friend| current_friends_uids.index(friend.uid) }
    #new_friends.each do |friend|
    #  friendship_batch_import << Friendship.new(:user_id => user.id, :friend_id => friend.id)
    #end
    #raise friendship_batch_import.to_yaml
    #Friendship.import friendship_batch_import
      #friend = User.create!(:uid => fq["uid"].to_s, :name => fq["name"], :gender => fq["sex"])
      #user.friendships.create!(:friend_id => fq["uid"].to_s)
      #friend.update_groups_with_fq(fq)
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
      self.friends.find(:all, :conditions => ["gender = ?", gender], :limit => 2, :order => "RANDOM()")
    end
  end




  def self.update_win_loss_by_uid(uid1, uid2) #ELO Rating system.
    user1 = User.find_by_uid(uid1)
    user2 = User.find_by_uid(uid2)      
    if !user1 or !user2 then return -1 end

    k = 40
    winp = 1/(10 ** ((user2.score - user1.score)/400.0) + 1)
    dscore = (k * (1 - winp))
    user1.update_attributes({:score => user1.score + dscore, :win => user1.win + 1})
    user2.update_attributes({:score => user2.score - dscore, :loss => user2.loss + 1})
    return dscore
end

  def add_friends(auth)
    #full query = "SELECT uid, name, sex, current_location, education_history, work_history  FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 =#{auth["uid"]})"
    friends = FbGraph::Query.new(
      "SELECT uid, name, sex, current_location FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 =#{auth["uid"]})"
    ).fetch(auth["credentials"]["token"])
    friends.each do |fq|
      existing_friend = User.find_by_uid(fq["uid"].to_s) || User.create!(:uid => fq["uid"].to_s, :name => fq["name"], :gender => fq["sex"])

      self.friendships.find_or_create_by_friend_id(existing_friend.id) if !self.inverse_friendships.find_by_friend_id(existing_friend.id)
      existing_friend.update_groups_with_fql(fq)
    end
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
end
