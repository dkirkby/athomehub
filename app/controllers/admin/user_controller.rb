class Admin::UserController < Admin::ApplicationController

  def index
    @users = User.all
  end

  def new
    @user = User.new    
  end
  
  def edit
    @user = User.find(params[:id])
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = 'User was successfully created.'
      redirect_to :action=>"index"
    else
      render :action=>"new"
    end
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      flash[:notice] = 'User was successfully updated.'
      redirect_to :action=>"index"
    else
      render :action=>"edit"
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy
    redirect_to :action=>"index"
  end

end
