class RolesController < ApplicationController
  before_action :authenticate_user!

  def index
    @roles = Role.all
  end

  def new
    @role = Role.new
  end

  def create
    @role = Role.new(role_params)
    @role.save
  end

  private
  def role_params
    params.require(:role).permit(:name, :email)
  end
end
