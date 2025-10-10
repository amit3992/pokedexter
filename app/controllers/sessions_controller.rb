class SessionsController < ApplicationController
  skip_before_action :require_login, only: [ :new, :create ]

  def new
    # Login form
    redirect_to root_path if logged_in?
  end

  def create
    email = params[:email]&.downcase&.strip
    user = User.find_by(email: email)

    if user
      session[:user_id] = user.id
      flash[:notice] = "Welcome back, #{user.email}!"
      redirect_to root_path
    else
      flash.now[:alert] = "Email not found. Please check your email address."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    flash[:notice] = "You have been logged out."
    redirect_to login_path
  end
end
