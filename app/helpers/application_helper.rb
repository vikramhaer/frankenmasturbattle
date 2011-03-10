module ApplicationHelper
  def user_tile(user)
    link_to(
      content_tag(:div, 
        image_tag("http://graph.facebook.com/#{user.uid}/picture", :class=>"battle") + 
        content_tag(:p, user.name.split(" ")[0], :class => "boldit lastround") +
        content_tag(:p, user.score.to_i, :class => "boldit score"), 
        :class => "friend-box"), 
      user, :class => "no-style",:target=>"_blank")
  end

end

