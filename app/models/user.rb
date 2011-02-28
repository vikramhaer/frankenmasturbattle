class User < ActiveRecord::Base
  def self.create_with_omniauth(auth)
    create! do |user|
      user.uid = auth["uid"]
      user.name = auth["user_info"]["name"]
      user.gender = auth["extra"]["user_hash"]["gender"]
      user.win = 0
      user.loss = 0
      user.score = 1600
    end
  end

  def update_networks(auth)
  end
    
end
