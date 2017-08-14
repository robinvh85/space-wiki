class IcoBaseController < ActionController::Base
  protect_from_forgery with: :exception

  layout 'ico'
end
