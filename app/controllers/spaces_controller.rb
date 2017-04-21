class SpacesController < ApplicationController
	before_action :authenticate_user!

	def index
		@subjects = Topic.where(level: 0)
		# binding.pry
	end
end
