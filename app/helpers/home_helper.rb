module HomeHelper
  def uid_img(user)
    "http://graph.facebook.com/#{user.uid}/picture?type=large"
  end
end
