class Admin::DeployController < ApplicationController
  before_action :authenticate_user!
  before_action :if_not_admin

  def index
    @create = Create.all
  end

  private
  def if_not_admin
    if current_user.is_admin == false
      redirect_to root_path
    end
  end
end
