class HomeController < ApplicationController
  skip_before_filter :authenticate, :except => "battle"

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
    else
      @no_ad = 1
    end

    respond_to do |format|
      format.html
    end
  end

  def battle
    session[:battle] = {} if !session[:battle] #initialize session[:battle] if not there
    #session[:battle][:last]
    session[:battle][:options] ||= {"gender" => current_user.opposite_gender, "network" => "0" } # 0 is default network for show only friends
    @options = session[:battle][:options]
    session[:battle][:uids] ||= current_user.random_match(session[:battle][:options])
    @right_user = session[:battle][:uids][-1]
    @left_user = session[:battle][:uids][-2]
    @enough_people = @left_user && @right_user

    respond_to do |format|
      format.html
    end
  end
  
  def battle_update
    if params["option_select"] then
      @options = {"gender" => params["gender"], "network" => params["network"]}
      session[:battle][:options] = @options
      raise session[:battle][:options].to_yaml
      session[:battle][:uids] = current_user.random_match(session[:battle][:options]) #make new batch if option changed
      

    elsif params[:choice] == "left" || params["choice"] == "right" || params["choice"] == "skip"
      current_user.increment_rating_count if params[:choice] != "skip"
      uids = session[:battle][:uids].pop(2).collect{ |stripped_user| stripped_user["uid"] }
      session[:battle][:last] = User.update_scores_by_uid(uids, params[:choice]) if params[:choice] != "skip"
      if session[:battle][:uids].empty? #refill the batch
        session[:battle][:uids] = current_user.random_match(session[:battle][:options]) 
        @ad_refresh = true
      end
    end
    @ad_refresh ||= false
    @right_user = session[:battle][:uids][-1]
    @left_user = session[:battle][:uids][-2]
    @enough_people = @left_user && @right_user

    respond_to do |format|
      format.js { render :layout=>false }
    end
  end
end
