class PoloniexBaseController < ActionController::Base
  protect_from_forgery with: :exception

  layout 'poloniex'
end
