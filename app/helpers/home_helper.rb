module HomeHelper
  def large_pic(user)
    "http://graph.facebook.com/#{user.uid}/picture?type=large"
  end

  def left_user
    session[:battle_uids][0]
  end

  def right_user
    session[:battle_uids][1]
  end
end
