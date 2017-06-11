class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def change_subject
		session[:current_subject_id] = params[:id]
		render json: {status: 'OK'}
  end

  def change_root_topic
    sleep(0.5)
  	if params[:id] == "null"
			session[:topic_root_id] = nil
		else
			session[:topic_root_id] = params[:id]
		end
		
		render json: {status: 'OK'}
  end

  def default_values
  	@subject_list = Topic.where(level: 0).select(:id, :title)

    # Get current_subject_id
    current_subject_id = @subject_list.first.id
    current_subject_id = session[:current_subject_id] unless session[:current_subject_id].nil?

  	render json: {
  		current_subject_id: current_subject_id,
  		# current_root_id: session[:current_root_id],
      current_root_id: nil,
  		subject_list: @subject_list
  	}
  end
end
