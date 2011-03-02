class User < ActiveRecord::Base
  has_many :friendships
  has_many :friends, :through => :friendships
  has_many :inverse_friendships, :class_name => "Friendship", :foreign_key => "friend_id"
  has_many :inverse_friends, :through => :inverse_friendships, :source => :user
  has_and_belongs_to_many :groups

  def self.create_with_omniauth(auth)
    create! do |user|
      user.uid = auth["uid"].to_s
      user.name = auth["user_info"]["name"]
      user.gender = auth["extra"]["user_hash"]["gender"]
    end
  end

  def random_match(gender, group = nil)
    if group
      group.users.find(:all, :conditions => ["gender = ? AND NOT id = ?", gender, self.id], :limit => 2,  :order => "RANDOM()", :select => "uid")
    else
      self.friends.find(:all, :conditions => ["gender = ?", gender], :limit => 2, :order => "RANDOM()", :select => "uid")
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

    loc_group = Group.find_by_gid(hash['location']['id'].to_s)
    if loc_group
      self.groups << loc_group if !self.groups.exists?(loc_group)
    else
      self.groups.create(:name => hash['location']['name'], :gid => hash['location']['id'].to_s, :type => 'loc') 
    end

    hash['work'].each do |job|
      job_group = Group.find_by_gid(job['employer']['id'].to_s)
      if job_group
        self.groups << job_group if !self.groups.exists?(job_group)
      else
        self.groups.create(:name => job['employer']['name'], :gid => job['employer']['id'].to_s, :type => 'job')
      end
    end
    
    hash['education'].each do |edu|
      edu_group = Group.find_by_gid(edu['school']['id'].to_s)
      if edu_group
        self.groups << edu_group if !self.groups.exists?(edu_group)
      else
        self.groups.create(:name => edu['school']['name'], :gid => edu['school']['id'].to_s, :type => 'edu')   
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
