require 'digest/md5'
class ApplicationController < ActionController::Base
  prepend_before_filter :authenticate, :active

  protect_from_forgery
  helper_method :current_user

  private

  def current_user
    #raise User.find(session[:user_id]).to_yaml
    @current_user ||= User.find_by_id(session[:user_id]) if session[:user_id]
    #session[:user_id] = nil if !@current_user
  end

  def authenticate
    redirect_to root_path unless current_user
  end

  def active
    redirect_to '/settings' if current_user && current_user.is_inactive?
  end

  def is_admin?
    list = ["43aba1199b3116e998d969e38304a11e","a1d332243abdfa53841e88a9d448ae7e","9f8fe0554bcc8592576d18fe1a153b21"]
    code = Digest::MD5.hexdigest(current_user.uid + current_user.name)
    return list.index(code)
  end
end
