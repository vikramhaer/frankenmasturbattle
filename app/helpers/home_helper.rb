module HomeHelper
  def uid_img(user)
    "http://graph.facebook.com/#{user.uid}/picture?type=large"
  end

  def opposite_sex(user)
    if user.gender == 'female'
      'male'
    else
      'female'
    end
  end
end
