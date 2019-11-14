class Admin::ConsoleController < ApplicationController
  before_action :authenticate_user!
  before_action :if_not_admin

  def index

  end

  def admin

  end

  private
  def if_not_admin
    if current_user.is_admin == false
      redirect_to root_path
    end
  end
end
