class TestController < ApplicationController
	def new
		@gallery = Gallery.new
	end

	def create
		@gallery = Gallery.new
    @gallery.image = params[:image]
    @gallery.save

    # redirect_to test_path(@gallery)
    render json: @gallery.to_json(:only => [:id], :methods => [:image_url])
	end

	def show
		@gallery = Gallery.find(params[:id])
	end

	def list
		@galleries = Gallery.all

		render json: @galleries.to_json(:only => [:id, :topic_id], :methods => [:image_url])
	end
end
