class HomeController < ApplicationController
  skip_before_filter :authenticate

  def about
    @no_ad = 1
    respond_to do |format|
      format.html
    end
  end

  def privacy
    @no_ad = 1
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
    session[:battle] = {} if !session[:battle] #initialize session[:battle] if not there
    session[:battle][:last] = nil
    session[:battle][:options] ||= {"gender" => current_user.opposite_gender, "network" => "0" } # 0 is default network for show only friends
    @options = session[:battle][:options]
    @left_user, @right_user = current_user.random_match(session[:battle][:options])
    if @left_user && @right_user
      session[:battle][:uids] = [@left_user.uid, @right_user.uid]
      @enough_people = true
    else
      session[:battle][:uids] = [nil, nil]
      @enough_people = false
    end
    respond_to do |format|
      format.html
    end
  end
  
  def battle_update
    if params["option_select"] then
      @options = {"gender" => params["gender"], "network" => params["network"]}
      session[:battle][:options] = @options
    elsif params[:choice] == "left" || params["choice"] == "right"
      current_user.increment_rating_count
      session[:battle][:last] = User.update_scores_by_uid(session[:battle][:uids], params[:choice])
    end
    
    #  @options = {"gender" => params["gender"], "network" => params["network"]}
    #end
    if @dscore == -1 then raise session[:battle][:uids].to_yaml end
    @left_user, @right_user = current_user.random_match(session[:battle][:options])
    if @left_user && @right_user
      session[:battle][:uids] = [@left_user.uid, @right_user.uid]
      @enough_people = true
    else
      session[:battle][:uids] = [nil, nil]
      @enough_people = false
    end

    respond_to do |format|
      format.js { render :layout=>false }
    end
  end
end
