class CurrentOrdersController < ApplicationController
	# before_action :authenticate_user!	

	def index
		@bid_orders = CurrentOrder.where(method: 'bid')
		@ask_orders = CurrentOrder.where(method: 'ask')
	end
end
