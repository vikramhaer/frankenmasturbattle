class HomeController < ApplicationController
  skip_before_filter :authenticate

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

  def index #this is the splash page
    if current_user then 
      redirect_to battle_path #if logged in just go to battle
      return
    end

    respond_to do |format|
      format.html
    end
  end

  def battle
    @options = {"gender" => current_user.gender, "network" => current_user.groups.first.id.to_s } # fix this in the morning
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
    @options = {"gender" => current_user.gender, "network" => current_user.groups.first.id.to_s } #fix this in the morning
    if params[:choice] == "left" || params["choice"] == "right"
      current_user.increment_rating_count
      uids = session[:battle_uids]
      session[:last_battle] = User.update_scores_by_uid(uids, params[:choice])
    end
    #if params["gender"] || params["network"]
    #  @options = {"gender" => params["gender"], "network" => params["network"]}
    #end
    if @dscore == -1 then raise session[:battle_uids].to_yaml end
    @left_user, @right_user = current_user.random_match()
    session[:battle_uids] = [@left_user.uid, @right_user.uid]
    respond_to do |format|
      format.js { render :layout=>false }
    end
  end
end
