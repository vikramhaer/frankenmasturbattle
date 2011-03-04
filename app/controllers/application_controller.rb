class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :current_user

  private

  def current_user
    #raise User.find(session[:user_id]).to_yaml
    @current_user ||= User.find_by_id(session[:user_id]) if session[:user_id]
    #session[:user_id] = nil if !@current_user
  end
end
