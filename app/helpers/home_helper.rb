module HomeHelper
  def large_pic(user)
    "http://graph.facebook.com/#{user.uid}/picture?type=large"
  end

  def left_user_name
    session[:battle_uids][0]["name"]
  end

  def right_user_name
    session[:battle_uids][1]["name"]
  end

  def left_user_pic
    image_tag "http://graph.facebook.com/#{session[:battle_uids][0].uid}/picture?type=large"
  end

  def right_user_pic
    image_tag "http://graph.facebook.com/#{session[:battle_uids][1].uid}/picture?type=large"
  end

  def last_left_pic
    image_tag "http://graph.facebook.com/#{session[:last_battle][0].uid}/picture?type=small" if session[:last_battle]
  end

  def last_right_pic
    image_tag "http://graph.facebook.com/#{session[:last_battle][1].uid}/picture?type=small" if session[:last_battle]
  end
end
