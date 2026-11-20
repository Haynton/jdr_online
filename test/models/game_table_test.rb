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

  test "a new table gets the default cover" do
    assert_equal GameTable::DEFAULT_COVER_IMAGE, GameTable.new.cover_image
  end

  test "a new table is a draft until it gets another status" do
    game_table = GameTable.new

    assert game_table.draft?
    game_table.status = "active"
    assert_not game_table.draft?
  end

  test "a cover outside the images of the app is refused" do
    game_table = GameTable.new(name: "Les Marches du Nord", cover_image: "../../secret")

    assert game_table.tap(&:validate).errors.of_kind?(:cover_image, :inclusion)
  end

  test "every cover of the list has its image in the assets" do
    GameTable::COVER_IMAGES.each do |cover_image|
      image_file = Rails.root.join("app/assets/images", GameTable.cover_image_path(cover_image))

      assert image_file.exist?, "missing #{image_file}"
    end
  end

  test "the players count leaves out the game master" do
    game_table = GameTable.create!(name: "Les Marches du Nord")
    game_table.participations.create!(user: create_user, role: :game_master)

    assert_equal 0, game_table.players_count
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
