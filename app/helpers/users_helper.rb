module UsersHelper
  def privacy_options(selected)
    options_for_select( [["Global (Everyone)",8], ["Networks and Friends",4], ["Friends Only",2], ["Nobody",1]] , selected)
  end
end
