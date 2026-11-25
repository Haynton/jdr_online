module ApplicationCable
  # A live connection (Action Cable) belongs to the signed-in user, read from the Devise session of the page; a visitor
  # gets none. Its channels check what this user may listen to (GameTableChannel)
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = signed_in_user || reject_unauthorized_connection
    end

    private

    def signed_in_user
      env["warden"]&.user
    end
  end
end
