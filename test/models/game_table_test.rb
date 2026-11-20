require "test_helper"

class GameTableTest < ActiveSupport::TestCase
  test "a table with a name is valid, even without a description" do
    assert GameTable.new(name: "Les Marches du Nord").valid?
  end

  test "a table needs a name" do
    game_table = GameTable.new(name: "")

    assert game_table.tap(&:validate).errors.of_kind?(:name, :blank)
  end

  test "a name longer than the database column is refused" do
    game_table = GameTable.new(name: "a" * (GameTable::NAME_MAX_LENGTH + 1))

    assert game_table.tap(&:validate).errors.of_kind?(:name, :too_long)
  end

  test "deleting a table deletes its participations" do
    game_table = GameTable.create!(name: "Les Marches du Nord")
    game_table.participations.create!(user: create_user, role: :game_master)

    assert_difference("Participation.count", -1) { game_table.destroy }
  end

  private

  def create_user
    User.create!(email: "game.master@example.com", username: "game_master", password: TEST_PASSWORD)
  end
end
