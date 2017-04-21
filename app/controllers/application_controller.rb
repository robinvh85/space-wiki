class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def change_subject
		session[:current_subject_id] = params[:id]
		render json: {status: 'OK'}
  end

  def change_root_topic
  	if params[:id] == "null"
			session[:topic_root_id] = nil
		else
			session[:topic_root_id] = params[:id]
		end

		sleep(0.2)
		render json: {status: 'OK'}
  end

  def default_values
  	@subject_list = @subjects = Topic.where(level: 0).select(:id, :title)

  	# binding.pry

  	render json: {
  		current_subject_id: session[:current_subject_id],
  		current_root_id: session[:topic_root_id],
  		subject_list: @subject_list,
  		test_2: session[:test_2],
  		test_3: session[:test_3]
  	}
  end
end
