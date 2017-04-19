class GalleriesController < ApplicationController

	def show
		topic = Topic.find(params['id'])
		render json: topic
	end

	def create
		@gallery = Gallery.new
    @gallery.image = params[:image]
    topic = Topic.find(params[:topic_id])
    @gallery.topic = topic
    
    # binding.pry

    if(@gallery.save)
			render json: {status: 'OK', gallery: @gallery.to_json(:only => [:id, :topic_id], :methods => [:image_url, :thump_url])}
		else
			render json: {status: 'NG'}
		end
	end

	def list
		@galleries = Gallery.where(topic_id: params['topic_id'])
		# binding.pry
		render json: @galleries.to_json(:only => [:id, :topic_id], :methods => [:image_url, :thump_url])
	end

end
