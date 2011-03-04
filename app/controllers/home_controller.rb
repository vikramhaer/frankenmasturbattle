class HomeController < ApplicationController
  
  def index
    if current_user
        @left_user, @right_user = current_user.random_match()
        session[:battle_uids] = [@left_user.uid, @right_user.uid]
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
    @left_user, @right_user = current_user.random_match()
    session[:battle_uids] = [@left_user.uid, @right_user.uid]
    respond_to do |format|
      format.js { render :layout=>false }
    end
  end
end
