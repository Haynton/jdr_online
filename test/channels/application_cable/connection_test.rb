require "test_helper"

module ApplicationCable
  class ConnectionTest < ActionCable::Connection::TestCase
    # What Devise leaves in the request of a page: the signed-in user, or nil for a visitor
    SignedInSession = Struct.new(:user)

    test "a signed-in user gets a connection of their own" do
      user = User.create!(email: "player@example.com", username: "joueur", password: TEST_PASSWORD)

      connect env: { "warden" => SignedInSession.new(user) }

      assert_equal user, connection.current_user
    end

    test "a visitor gets no connection" do
      assert_reject_connection { connect env: { "warden" => SignedInSession.new(nil) } }
    end
  end
end
