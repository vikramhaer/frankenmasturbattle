class SessionsController < ApplicationController
  skip_before_filter :authenticate

  def create
    auth = request.env["omniauth.auth"]
    session[:uid] = auth["uid"]
    #if !Beta.where(:uid => auth["uid"],:access => true).exists?
    #  redirect_to new_beta_path
    #  return
    #end
    user = User.find_by_uid(auth["uid"]) || User.create_with_omniauth(auth)
    user.login_procedure(auth)
    session[:user_id] = user.id
    redirect_to battle_path, :notice => "Signed in!"
  end

  def destroy
    session[:battle][:uids] = nil
    session[:battle][:last] = nil
    session[:user_id] = nil
#    redirect_to "http://www.facebook.com/logout.php?app_key=#{api_key}&session_key=#{session_key}&next=google.com&confirm=1", :notice => "Signed out!"
    redirect_to root_url, :notice => "Signed Out!"
  end
end
#http://facebook.com/logout.php?app_key=FACEBOOK_API_KEY&session_key=SESSION_KEY&next=REDIRECT_URL
