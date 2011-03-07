class SessionsController < ApplicationController
  skip_before_filter :authenticate

  def create
    auth = request.env["omniauth.auth"]
    user = User.find_by_uid(auth["uid"]) || User.create_with_omniauth(auth)
    user.login_procedure(auth)
    session[:fb_token] = auth["credentials"]["token"]
    session[:user_id] = user.id
    redirect_to battle_path, :notice => "Signed in!"
  end

  def destroy
    api_key = "d44a0892b99bf2c4fc75470e39c1de6b"
    session_key = session[:fb_token].split("|")[1]
    session[:battle][:uids] = nil
    session[:battle][:last] = nil
    session[:fb_token] = nil
    session[:user_id] = nil
#    redirect_to "http://www.facebook.com/logout.php?app_key=#{api_key}&session_key=#{session_key}&next=google.com&confirm=1", :notice => "Signed out!"
    redirect_to root_url, :notice => "Signed Out!"
  end
end
#http://facebook.com/logout.php?app_key=FACEBOOK_API_KEY&session_key=SESSION_KEY&next=REDIRECT_URL
