# The legal notice of the site: its publisher, its hosts, and the credits that the licenses of the game rules ask
# for. Open to visitors (a link at the foot of the home page); a signed in user also finds it in the settings
class LegalNoticesController < ApplicationController
  skip_before_action :authenticate_user!, only: :show

  def show
  end
end
