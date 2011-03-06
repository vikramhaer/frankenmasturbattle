class HomeController < ApplicationController

  def about
    respond_to do |format|
      format.html
    end
  end

  def privacy
    respond_to do |format|
      format.html
    end
  end

  def index
      redirect_to splash_path
    #respond_to do |format|
    #  format.html
    #  format.js { render :layout=>false }
    #end
  end

  def splash
    respond_to do |format|
      format.html
    end
  end

  def battle
    users = current_user.random_match()
    @left_user = users[0]
    @right_user = users[1]
    session[:battle_uids] = [users[0].uid, users[1].uid]
    session[:last_battle] = nil
    respond_to do |format|
      format.html
    end
  end
  
  def battle_update
    if params[:choice] == "left" || params["choice"] == "right"
      current_user.increment_rating_count
      uids = session[:battle_uids]
      session[:last_battle] = User.update_scores_by_uid(uids, params[:choice])
    end
    if @dscore == -1 then raise session[:battle_uids].to_yaml end
    @left_user, @right_user = current_user.random_match()
    session[:battle_uids] = [@left_user.uid, @right_user.uid]
    respond_to do |format|
      format.js { render :layout=>false }
    end
  end
end
