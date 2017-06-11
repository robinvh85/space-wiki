class SpacesController < ApplicationController
  before_action :authenticate_user!

  def index
    @current_menu_id = params[:topic_id]
    @root_topic_id = nil

    unless(@current_menu_id.nil?)
      topic = Topic.find(@current_menu_id)
      @root_topic_id = Topic.get_root(topic).id unless topic.nil?
    end
  end

end
