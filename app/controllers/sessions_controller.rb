class SessionsController < ApplicationController
  skip_before_filter :authenticate, :active

  def create
    auth = request.env["omniauth.auth"]
    session[:uid] = auth["uid"]
    session[:access_token] = auth["credentials"]["token"]

    user = User.find_by_uid(auth["uid"]) || User.create_with_omniauth(auth)
    session[:user_id] = user.id
    user.standard_login(auth)
    if user.login_count == 1 then 
      session[:loading_in_progress] = true
      redirect_to "/invite"
    else
      redirect_to battle_path, :notice => "Signed in!"
    end
  end

  def destroy
    session[:uid] = nil
    session[:battle] = nil
    session[:user_id] = nil
    session[:access_token] = nil
    redirect_to root_url, :notice => "Signed Out!"
  end
end
#http://facebook.com/logout.php?app_key=FACEBOOK_API_KEY&session_key=SESSION_KEY&next=REDIRECT_URL
