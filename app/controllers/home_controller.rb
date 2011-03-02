class HomeController < ApplicationController
  
  def index
    if current_user
        session[:battle_uids] = current_user.random_match('male')
    end
    respond_to do |format|
      format.html
      format.js { render :layout=>false }
    end
  end
  
  def battle
    if params[:choice] == "left" then @dscore = User.update_win_loss_by_uid(session[:battle_uids][0]['uid'], session[:battle_uids][1]['uid']) end
    if params[:choice] == "right" then @dscore = User.update_win_loss_by_uid(session[:battle_uids][1]['uid'], session[:battle_uids][0]['uid']) end
    if @dscore == -1 then raise session[:battle_uids].to_yaml end
    session[:battle_uids] = current_user.random_match('male')
    respond_to do |format|
      format.js { render :layout=>false }
    end
  end
end
