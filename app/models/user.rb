class User < ActiveRecord::Base
  has_many :friendships
  has_many :friends, :through => :friendships
  has_many :inverse_friendships, :class_name => "Friendship", :foreign_key => "friend_id"
  has_many :inverse_friends, :through => :inverse_friendships, :source => :user

  def self.create_with_omniauth(auth)
    create! do |user|
      user.uid = auth["uid"]
      user.name = auth["user_info"]["name"]
      user.gender = auth["extra"]["user_hash"]["gender"]
    end
  end

  def update_groups(auth)
    #raise self.friends.to_yaml
  end

  def add_friends(auth)
    #full query = "SELECT uid, name, sex, current_location, education_history, work_history  FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 =#{auth["uid"]})"
    friends = FbGraph::Query.new(
      "SELECT uid, name, sex FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 =#{auth["uid"]})"
    ).fetch(auth["credentials"]["token"])    
    friends.each do |friend|
      existing_friend = User.find_by_uid(friend["uid"]) || User.create!(:uid => friend["uid"], :name => friend["name"], :gender => friend["sex"])

      self.friendships.find_or_create_by_friend_id(existing_friend.id) if !self.inverse_friendships.find_by_friend_id(existing_friend.id)
    end
  end
    
end
