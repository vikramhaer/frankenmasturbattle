module HomeHelper
  def large_pic(user)
    image_tag("http://graph.facebook.com/#{user.uid}/picture?type=large")
  end

  def reg_pic(user, params = nil)
    image_tag("http://graph.facebook.com/#{user.uid}/picture", params)
  end

  def left_user
    session[:battle_uids][0]
  end

  def right_user
    session[:battle_uids][1]
  end

  def old_left_user
    session[:last_battle][0]
  end

  def old_right_user
    session[:last_battle][1]
  end

  def round(score)
    score.round.to_s
  end

end
