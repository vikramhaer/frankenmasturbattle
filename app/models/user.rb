class User < ActiveRecord::Base
  def self.create_with_omniauth(auth)
    add_friends(auth)
    create! do |user|
      user.uid = auth["uid"]
      user.name = auth["user_info"]["name"]
      user.gender = auth["extra"]["user_hash"]["gender"]
    end
  end

  def self.add_friends(auth)
    #full query = "SELECT uid, name, sex, current_location, education_history, work_history  FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 =#{auth["uid"]})"
    array = FbGraph::Query.new(
      "SELECT uid, name, sex FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 =#{auth["uid"]})"
    ).fetch(auth["credentials"]["token"])    
    array.each do |friend|
      if !User.find_by_uid(friend["uid"])
        create! do |user|
          user.uid = friend["uid"]
          user.name = friend["name"]
          user.gender = friend["sex"]
        end
      end
    end
  end

  def update_networks(auth)
  end
    
end
