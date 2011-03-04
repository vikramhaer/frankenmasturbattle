class HomeController < ApplicationController
  
  def index
    if current_user
        session[:battle_uids] = current_user.random_match()
        session[:last_battle] = nil
    end
    respond_to do |format|
      format.html
      format.js { render :layout=>false }
    end
  end
  
  def battle
    if params[:choice] == "left" || params["choice"] == "right"
      session[:last_battle] = User.update_scores_by_uid(session[:battle_uids], params[:choice]) 
    end    
    if @dscore == -1 then raise session[:battle_uids].to_yaml end

    session[:battle_uids] = current_user.random_match()
    respond_to do |format|
      format.js { render :layout=>false }
    end
  end
end
