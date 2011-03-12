class UsersController < ApplicationController
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

  # GET /users/1
  # GET /users/1.xml
  def show
    @user = User.find(params[:id])
    #raise @user.all_friends_order_by_score_desc_limit(12).to_yaml
    @user_friends = @user.all_friends_order_by_score_desc_limit(12)
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
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
    raise params.to_yaml
    @settings = []
    @user = current_user
    respond_to do |format|
      format.html
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
