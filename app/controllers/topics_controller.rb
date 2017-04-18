class TopicsController < ApplicationController
	before_action :authenticate_user!
	
	def index
		topics = Topic.first

		# Render max 3 level
		render json: topics.to_json(
			:include => { 
				:children => { 
					:only => [:id, :title],
					:include => { 
						:children => { 
							:only => [:id, :title],
							:include => { :children => { :only => [:id, :title] }}
						} 
					}
				} 
			}, 
			:only => [:id, :title] )
	end

	def show
		topic = Topic.find(params['id'])
		render json: topic
	end

	def create
		status = 'OK'
		errors = nil;
		parent 	= Topic.find(params[:parent][:id])
		topic 	= Topic.new(topic_params)		
		topic.parent_id = parent.id
		topic.level = parent.level + 1
				
		unless topic.save
			status = 'NG'
			errors = topic.errors
		end

		if status == "NG"
			render json: {status: status, errors: errors}, status: 422
		else
			render json: {status: status, topic: topic}
		end
	end

	def update
		topic = Topic.find(params[:id]);
		status = 'OK'
		message = '';

		unless topic.update(topic_params)
			status = 'NG'
			message = topic.errors
		end

		if status == "NG"
			render json: {status: status, message: message}, status: 422
		else
			render json: {status: status}
		end
	end

	def topic_params
		params.require(:topic).permit(:title, :content)
	end

end
