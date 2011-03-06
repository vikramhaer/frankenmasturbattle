module RankingsHelper
  def see_more_box(text, path)
    link_to(
      content_tag(:div, 
        content_tag(:h3, text),        
        :class => "friend-box"), 
      path, :class => "no-style")
  end
end
