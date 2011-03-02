class SessionsController < ApplicationController
  def create
    auth = request.env["omniauth.auth"]
    user = User.find_by_uid(auth["uid"]) || User.create_with_omniauth(auth)
    user.add_friends(auth) if user.friendships.empty?
    user.update_groups(auth)
    session[:user_id] = user.id
    redirect_to user, :notice => "Signed in!"
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_url, :notice => "Signed out!"
  end
end
