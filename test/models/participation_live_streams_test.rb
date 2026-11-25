require "test_helper"

# Someone who leaves a table stops hearing it: their connections are told to reconnect, and GameTableChannel refuses
# the table when they subscribe again
class ParticipationLiveStreamsTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  test "a player removed from a table has their connections reconnected" do
    game_master = User.create!(email: "gm@example.com", username: "maitre", password: TEST_PASSWORD)
    player = User.create!(email: "player@example.com", username: "joueur", password: TEST_PASSWORD)
    game_table = GameTableCreator.new(user: game_master, attributes: { name: "La Crypte" },
                                      sheet_template: SheetTemplate.create!(name: "Fantasy", locale: "fr")).call
    participation = game_table.participations.create!(user: player, role: "player")

    assert_broadcast_on("action_cable/#{player.to_gid_param}", { type: "disconnect", reconnect: true }) do
      participation.destroy
    end
  end
end
