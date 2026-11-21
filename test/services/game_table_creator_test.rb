require "test_helper"

class GameTableCreatorTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "game.master@example.com", username: "game_master", password: TEST_PASSWORD)
    @sheet_template = SheetTemplate.create!(name: "Fantasy", locale: "fr", character_fields: { "fields" => [] })
  end

  test "creates a draft table with its template copied, and makes its creator the game master" do
    game_table = create_table(name: "Les Marches du Nord")

    assert game_table.persisted?
    assert game_table.draft?
    assert_equal @sheet_template.snapshot, game_table.template_snapshot
    assert_equal [@user], game_table.participations.game_master.map(&:user)
  end

  test "saves nothing when the table is invalid, and gives back its errors" do
    game_table = nil

    assert_no_difference(["GameTable.count", "Participation.count"]) { game_table = create_table(name: "") }
    assert game_table.errors.of_kind?(:name, :blank)
  end

  test "a table needs a template" do
    game_table = GameTableCreator.new(user: @user, attributes: { name: "Les Marches du Nord" }, sheet_template: nil).call

    assert_not game_table.persisted?
    assert game_table.errors.of_kind?(:sheet_template, :blank)
  end

  test "the table is not kept when its game master participation cannot be saved" do
    creator = GameTableCreator.new(user: nil, attributes: { name: "Les Marches du Nord" }, sheet_template: @sheet_template)

    assert_no_difference("GameTable.count") { creator.call }
  end

  private

  def create_table(name:)
    GameTableCreator.new(user: @user, attributes: { name: name }, sheet_template: @sheet_template).call
  end
end
