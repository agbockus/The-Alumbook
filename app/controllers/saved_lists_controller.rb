# author: Brett Bush
# modified by James Maher and Andrew Bockus

class SavedListsController < ApplicationController
  before_action :set_saved_list, only: [:show, :edit, :update, :destroy]

  # Display: views/saved_list/index.html.erb
  def index
    @saved_lists = SavedList.where("login_id = ?", current_login.id)
  end

  # Display: views/saved_list/show.html.erb
  #      or: views/saved_list/show.xls.erb
  def show
    # Obtain selected saved list
    @saved_list = SavedList.find(params[:id])

    # Obtain users in selected saved list
    @users = User.joins('INNER JOIN saved_list_users ON saved_list_users.user_id = users.id').where('saved_list_users.saved_list_id = ?', @saved_list.id)

    # Account for HTML or XLS page
    respond_to do |format|
      format.html do
        # Do nothing
      end
      format.xls do

        # Create file name from: report name and current datetime, downcasing it, adding .xls extension, and replace all invalid file name characters with underscores (including spaces)
        headers["Content-Disposition"] = "attachment; filename=\"" + @saved_list.list_name.downcase.gsub(/[\x00\/\\:\*\?\"<>\| ]/, '_') + "_" + DateTime.now.strftime("%m%d%Y_%I%M%p") + ".xls\""

      end
    end
  end

  # Delete user method - Created by Andrew Bockus
  def delete_user
    saved_list = SavedList.find(params[:id])
    list_users = saved_list.saved_list_users
    table_to_delete = list_users.where("user_id = ?", params[:user_id])
    table_to_delete.first.delete

    redirect_to saved_lists_path
  end

  # Create new saved list
  # Redirect to: views/saved_list/index.html.erb
  def create
    if params[:new_list_name].nil? || params[:new_list_name].blank? && params[:list_name] != ""
      @list_name = params[:list_name]
      @saved_list = SavedList.find(params[:list_name])
      @user_ids = params["user_ids"]
      # Removes duplicates from Saved Lists
      # Authored by Cornelius Donley
      @user_ids_uniq = Array.new.uniq
      @saved_list.users.each do |u|
        @user_ids_uniq.push u
      end
      @user_ids.each do |u|
        @user_ids_uniq.push (u)
      end
      # End remove duplicates code

      @user_ids_uniq.each do |user_id|
        SavedListUser.create(saved_list_id: @saved_list.id, user_id: user_id)
      end
      @saved_list.save
      redirect_to @saved_list
    elsif !params["user_ids"].nil? && (params[:new_list_name] != "" && !params[:new_list_name].nil? || !params[:new_list_name].blank?)
      # Create new saved list table entry
      @saved_list = SavedList.new
      # Store attributes
      @saved_list.list_name = params[:new_list_name]
      @saved_list.login_id = params[:login_id]
      @saved_list.date_saved = params[:date_saved]

      # Save the saved list
      respond_to do |format|
        if @saved_list.save

          # Create new user saved list entries for all users in list
          @user_ids = params["user_ids"]
          @user_ids.each do |user_id|
            SavedListUser.create(saved_list_id: @saved_list.id, user_id: user_id)
          end

          format.html { redirect_to @saved_list, notice: 'Saved list was successfully created.' }
          format.json { render :show, status: :created, location: @saved_list }
        else
          format.html { render :new }
          format.json { render json: @saved_list.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to saved_lists_path
    end
  end

  # Destroy a saved list
  # Redirect to: views/saved_list/index.html.erb
  def destroy

    # Obtain selected saved list
    @saved_list = SavedList.find(params[:id])
    @saved_list_users = SavedListUser.where("saved_list_id = ?", @saved_list.id)

    # Destroy user saved list entries for all users in list
    @saved_list_users.each do |saved_list_user|
      saved_list_user.destroy
    end

    # Destroy saved list
    @saved_list.destroy

    respond_to do |format|
      format.html {
        redirect_to :action => 'index'
        flash[:notice] ='Saved list was successfully deleted.'
      }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_saved_list
      @saved_list = SavedList.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def saved_list_params
      params[:saved_list]
    end
end
