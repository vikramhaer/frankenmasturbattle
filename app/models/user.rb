class User < ActiveRecord::Base
  has_many :friendships
  has_many :friends, :through => :friendships
  has_many :inverse_friendships, :class_name => "Friendship", :foreign_key => "friend_id"
  has_many :inverse_friends, :through => :inverse_friendships, :source => :user
  has_and_belongs_to_many :groups

  def self.create_with_omniauth(auth)
    create! do |user|
      user.uid = auth["uid"]
      user.name = auth["user_info"]["name"]
      user.gender = auth["extra"]["user_hash"]["gender"]
    end
  end

  def add_friends(auth)
    #full query = "SELECT uid, name, sex, current_location, education_history, work_history  FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 =#{auth["uid"]})"
    friends = FbGraph::Query.new(
      "SELECT uid, name, sex, current_location FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 =#{auth["uid"]})"
    ).fetch(auth["credentials"]["token"])
    friends.each do |fq|
      existing_friend = User.find_by_uid(fq["uid"]) || User.create!(:uid => fq["uid"], :name => fq["name"], :gender => fq["sex"])

      self.friendships.find_or_create_by_friend_id(existing_friend.id) if !self.inverse_friendships.find_by_friend_id(existing_friend.id)
      existing_friend.update_groups_with_fql(fq)
    end
  end

  def update_groups(auth)
    #fq = FbGraph::Query.new("SELECT work_history,education_history,current_location FROM user where uid=#{auth["uid"]}").fetch(auth["credentials"]["token"])
    hash = auth['extra']['user_hash']
    self.groups.find_or_create_by_name_and_gid_and_type(hash['location']['name'], hash['location']['id'], 'loc')
    hash['work'].each do |job|
      self.groups.find_or_create_by_name_and_gid_and_type(job['employer']['name'], job['employer']['id'], 'job')
    end
    hash['education'].each do |edu|
      self.groups.find_or_create_by_name_and_gid_and_type(edu['school']['name'], edu['school']['id'], 'edu')
    end
  end

  def update_groups_with_fql(fq)
    self.groups.find_or_create_by_name_and_gid_and_type(fq['current_location']['name'], fq['current_location']['id'], 'loc') if fq['current_location']
  end
end
