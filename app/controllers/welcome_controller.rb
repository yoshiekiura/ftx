class WelcomeController < ApplicationController
  before_filter :auth_member!
  layout 'landing'



  def index
    @lobby_message = LobbyMessage.last
    @mon = Date.today.mon
  end

end
