class RankingController < ApplicationController
  def global
    @top_females = User.female.top25
    @top_males = User.male.top25
    respond_to do |format|
      format.html
    end
  end

  def friends
    @top_females = current_user.friends.female.top25
    @top_males = current_user.friends.male.top25
    respond_to do |format|
      format.html
    end
  end

  def group
    group_id = params[:id]
    @group = Group.find_by_id(params[:id])
    if !@group then 
      raise "Group with id #{params[:id]} not found"
    else
      @top_females = @group.users.female.top25
      @top_males = @group.users.male.top25
      respond_to do |format|
        format.html
      end
    end
  end

  def index
    @global_males = User.male.top5
    @global_females = User.female.top5
    @friend_males = current_user.friends.male.top5
    @friend_females = current_user.friends.female.top5
    @groups = current_user.groups

    respond_to do |format|
      format.html
    end
  end

end
