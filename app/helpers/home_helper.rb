module HomeHelper
  def large_pic(user, params = nil)
    image_tag("http://graph.facebook.com/#{user.uid}/picture?type=large", params)
  end

  def reg_pic(user, params = nil)
    image_tag("http://graph.facebook.com/#{user.uid}/picture", params)
  end

  def left_user
    session[:battle][:uids][0]
  end

  def right_user
    session[:battle][:uids][1]
  end

  def old_left_user
    session[:battle][:last][0]
  end

  def old_right_user
    session[:battle][:last][1]
  end

  def network_options_with_friends(networks, id)
    "<option value=\"0\">Friends Only</option>".html_safe + options_from_collection_for_select(networks, "id", "name", id)
  end

end
