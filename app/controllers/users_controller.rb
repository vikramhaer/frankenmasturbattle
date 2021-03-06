class UsersController < ApplicationController

  skip_before_filter :active, :only => "settings"

  # GET /users/1
  # GET /users/1.xml
  def show
    @user = User.find_by_id(params[:id])
    @is_invitable = !Friendship.where(:user_id => current_user.id, :friend_id => params[:id]).empty? && @user.login_count==0
    if !@user then
      render :inline => "<h1>User not found</h1>", :layout => true
    elsif @user.is_inactive?
      render :inline => "<h1>User not active</h1>", :layout => true
    else 
      @user_friends = @user.is_new? ? [] : @user.all_friends_order_by_score_desc_limit(12) 
      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @user }
      end
    end
  end

  def all_friends
    @user = User.find(params[:id])
    if params[:cmd] == "update_friends" then
      current_user.force_group_update(session[:access_token])
    end

    @friends = @user.friends.order("gender asc, win + loss asc")
    @inverse_friends = @user.inverse_friends
    @male_total = @user.friends.male.size
    @male_unrated = @user.friends.male.unrated.size
    @female_total = @user.friends.female.size
    @female_unrated= @user.friends.female.unrated.size
    respond_to do |format|
      format.html
    end
  end

  def settings
    @settings = current_user.settings
    if params["update"]
      if params["account_status_message"] == "deactivate" then
        current_user.update_attributes(:settings => 0);
      elsif params["account_status_message"] == "reactivate" then
        current_user.update_attributes(:settings => 1);
      else
        flash[:error] = "account status change message not recognized"
      end
    end
    @user = current_user
    respond_to do |format|
      format.html {render :layout => "noad"} 
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /users
  # POST /users.xml
  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        format.html { redirect_to(@user, :notice => 'User was successfully created.') }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /users
  # GET /users.xml
  def index
    @user_count = User.count
    @group_count = Group.count
    @users = User.find(:all, :order => "score desc")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to(@user, :notice => 'User was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end
  end
end
