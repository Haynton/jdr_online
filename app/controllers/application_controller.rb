class ApplicationController < ActionController::Base
  include Locale

  before_action :authenticate_user!
end
