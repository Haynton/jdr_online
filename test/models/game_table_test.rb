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

  test "a new table starts at level 1" do
    assert_equal 1, GameTable.new.starting_level
  end

  test "a starting level from 1 to 20 is accepted" do
    [GameTable::STARTING_LEVELS.min, GameTable::STARTING_LEVELS.max].each do |starting_level|
      assert GameTable.new(name: "Les Marches du Nord", starting_level: starting_level).valid?
    end
  end

  test "a starting level below 1 or above 20 is refused" do
    [0, 21, nil].each do |starting_level|
      game_table = GameTable.new(name: "Les Marches du Nord", starting_level: starting_level)

      assert game_table.tap(&:validate).errors.of_kind?(:starting_level, :inclusion)
    end
  end

  test "the database refuses a starting level outside 1 to 20 too" do
    game_table = GameTable.create!(name: "Les Marches du Nord")

    assert_raises(ActiveRecord::StatementInvalid) { game_table.update_column(:starting_level, 21) }
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

  test "every image of the covers folder is in the list, with a theme" do
    image_names = Rails.root.glob("app/assets/images/covers/*.webp").map { |image_file| image_file.basename(".webp").to_s }

    assert_equal image_names.sort, GameTable::COVER_IMAGES.sort
    assert_equal %w[fantasy horror science_fiction], GameTable::COVER_THEME_NAMES
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

  test "the first step of the creation asks for a sheet template" do
    game_table = GameTable.new(name: "Les Marches du Nord")

    assert game_table.valid?
    assert_not game_table.valid?(:details)
    assert game_table.errors.of_kind?(:sheet_template, :blank)
  end

  test "choosing a template copies it into the table" do
    sheet_template = SheetTemplate.new(name: "Fantasy", locale: "fr",
                                       character_fields: { "fields" => [{ "key" => "hp" }] })
    game_table = GameTable.new(name: "Les Marches du Nord")

    game_table.use_sheet_template(sheet_template)

    assert_equal sheet_template, game_table.sheet_template
    assert_equal sheet_template.snapshot, game_table.template_snapshot
  end

  test "a table without a template has an empty copy" do
    game_table = GameTable.new(name: "Les Marches du Nord", template_snapshot: { "character_fields" => {} })

    game_table.use_sheet_template(nil)

    assert_equal({}, game_table.template_snapshot)
  end

  test "a new table gets its own invitation token" do
    first_table = GameTable.create!(name: "Les Marches du Nord")
    second_table = GameTable.create!(name: "L'Ombre du Dragon")

    assert first_table.invite_token.present?
    assert_not_equal first_table.invite_token, second_table.invite_token
  end

  test "the steps follow each other, to the summary" do
    assert_equal "settings", GameTable.next_creation_step("details")
    assert_equal "catalog", GameTable.next_creation_step("settings")
    assert_equal "npcs", GameTable.next_creation_step("catalog")
    assert_equal "maps", GameTable.next_creation_step("npcs")
    assert_equal "summary", GameTable.next_creation_step("maps")
    assert_nil GameTable.next_creation_step("summary")
  end

  test "the creation is taken up at the step reached" do
    game_table = GameTable.create!(name: "Les Marches du Nord")
    assert_equal "details", game_table.resume_creation_step

    game_table.reach_creation_step("summary")
    assert_equal "summary", game_table.resume_creation_step

    game_table.update!(creation_step: 5)
    assert_equal "maps", game_table.resume_creation_step
  end

  test "a draft saved past the last step is taken up at the summary" do
    game_table = GameTable.create!(name: "Les Marches du Nord", creation_step: GameTable::CREATION_STEPS.size + 1)

    assert_equal "summary", game_table.resume_creation_step
  end

  test "taking up an earlier step keeps the progress made" do
    game_table = GameTable.create!(name: "Les Marches du Nord")
    game_table.reach_creation_step("summary")

    game_table.reach_creation_step("details")

    assert_equal "summary", game_table.resume_creation_step
  end

  test "finishing the creation makes the table ready" do
    game_table = GameTable.create!(name: "Les Marches du Nord")

    game_table.finish_creation!

    assert_not game_table.draft?
    assert_equal GameTable::READY_STATUS, game_table.status
  end

  private

  def create_user
    User.create!(email: "game.master@example.com", username: "game_master", password: TEST_PASSWORD)
  end
end
