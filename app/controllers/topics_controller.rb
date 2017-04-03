class TopicsController < ApplicationController

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

	def update
		topic = Topic.find(params[:id]);
		status = 'OK'
		message = '';

		unless topic.update(topic_params)
			status = 'NG'
			message = topic.errors
		end

		render json: {status: status, message: message}
	end

	def topic_params
		params.require(:topic).permit(:title, :content)
	end

end
