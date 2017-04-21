class SubjectsController < ApplicationController
	before_action :authenticate_user!
	before_action :set_subject, only: [:edit, :update, :destroy]

	def list
		@subjects = Topic.where(level: 0).select(:id, :title)
		render json: @subjects
	end

	def index
		@subjects = Topic.where(level: 0)
	end

	def new
		@subject = Topic.new
	end

	def create
		@subject = Topic.new(subject_params)
		@subject.level = 0
		@subject.parent_id = nil

    if(@subject.save)
			flash.notice = "Subject '#{@subject.title}' has been created!"
			redirect_to subjects_path
		else
			flash.notice = "Subject '#{@subject.title}' has been failed!"
			redirect_to new_subject_path
		end
	end

	def edit
		
	end

	def update
		@subject.update(subject_params)
		flash.notice = "Subject '#{@subject.title}' has been updated!"

		redirect_to subjects_path
	end

	def destroy
		@subject.delete

		flash.notice = "Subject '#{@subject.title}' has been deleted!"
		redirect_to subjects_path
	end

	private
	def subject_params
		params.require(:topic).permit(:title)
	end

	def set_subject
		@subject = Topic.find(params['id'])
	end
end
