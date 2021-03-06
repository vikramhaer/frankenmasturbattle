module HomeHelper
  def history_tile(user, outcome)
    link_to(
      content_tag(:div, 
        image_tag("http://graph.facebook.com/#{user.uid}/picture", :class=>"battle") + 
        content_tag(:p, user.name.split(" ")[0], :class => "lastround") +
        content_tag(:p, user.score.to_i, :class => "boldit score") +
        content_tag(:p, 
          content_tag(:span, user.win.to_s, :class => "boldit green") +
          content_tag(:span, "   :   ") + 
          content_tag(:span, user.loss.to_s, :class => "boldit red"),
          :class => "winloss"), 
        :class => outcome), 
      user, :class => "no-style")
  end
  
  def large_pic(user, params = nil)
    image_tag("http://graph.facebook.com/#{user["uid"]}/picture?type=large", params)
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
    ("<option value=\"0\">All Friends (" + Friendship.where(:user_id => current_user.id).count.to_s + ")</option>").html_safe + 
        options_from_collection_for_select(networks, "id", "name_and_size", id)
  end

  def bigtile(user, side)
    if user != nil
      content_tag(:div, large_pic(user, {:class => "fixedheight"}), :class => "battlepic") + 
      content_tag(:p, user["name"], :class => "name")
    else
      "<br><br><br><br>Not enough people in this category. Please pick another one.".html_safe
    end
  end
end

