class BetasController < ApplicationController
  skip_before_filter :authenticate, :only =>["new", "create", "confirmation"]
  # GET /betas
  # GET /betas.xml
  def index
    @betas = Beta.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @betas }
    end
  end

  # GET /betas/1
  # GET /betas/1.xml
  def show
    @beta = Beta.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @beta }
    end
  end

  # GET /betas/new
  # GET /betas/new.xml
  def new
    @beta = Beta.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @beta }
    end
  end

  # GET /betas/1/edit
  def edit
    @beta = Beta.find(params[:id])
  end

  # POST /betas
  # POST /betas.xml

  def confirmation
    respond_to do |format|
      format.html
    end
  end  

  def create
    @beta = Beta.new(params[:beta])
    if Beta.find_by_email(@beta.email) then
      redirect_to :action=>"confirmation"
      return
    end
    @beta.uid = session[:uid]
    @beta.access = (@beta.email == "frankenmasturbattle_#{session["uid"]}")

    respond_to do |format|
      if @beta.save
        format.html { redirect_to(:action=>"confirmation", :notice => 'Beta was successfully created.') }
        format.xml  { render :xml => @beta, :status => :created, :location => @beta }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @beta.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /betas/1
  # PUT /betas/1.xml
  def update
    @beta = Beta.find(params[:id])

    respond_to do |format|
      if @beta.update_attributes(params[:beta])
        format.html { redirect_to(@beta, :notice => 'Beta was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @beta.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /betas/1
  # DELETE /betas/1.xml
  def destroy
    @beta = Beta.find(params[:id])
    @beta.destroy

    respond_to do |format|
      format.html { redirect_to(betas_url) }
      format.xml  { head :ok }
    end
  end
end
