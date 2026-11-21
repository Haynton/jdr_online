require "test_helper"

class SheetTemplateTest < ActiveSupport::TestCase
  test "a predefined template is valid with a name and a language of the app" do
    assert SheetTemplate.new(name: "Fantasy", locale: "fr").valid?
  end

  test "a predefined template is written in a language of the app" do
    assert SheetTemplate.new(name: "Fantasy", locale: "de").tap(&:validate).errors.of_kind?(:locale, :inclusion)
    assert SheetTemplate.new(name: "Fantasy").tap(&:validate).errors.of_kind?(:locale, :inclusion)
  end

  test "a game master's template has no language: it is written in their own words" do
    sheet_template = SheetTemplate.new(name: "Mon jeu", owner: create_user("owner"), locale: "fr")

    assert sheet_template.tap(&:validate).errors.of_kind?(:locale, :present)
  end

  test "a template needs a name" do
    sheet_template = SheetTemplate.new(name: "")

    assert sheet_template.tap(&:validate).errors.of_kind?(:name, :blank)
  end

  test "a name longer than the database column is refused" do
    sheet_template = SheetTemplate.new(name: "a" * (SheetTemplate::NAME_MAX_LENGTH + 1))

    assert sheet_template.tap(&:validate).errors.of_kind?(:name, :too_long)
  end

  test "a template without an owner is provided by the app" do
    assert SheetTemplate.new(name: "Fantasy", locale: "fr").predefined?
    assert_not SheetTemplate.new(name: "Mon jeu", owner: create_user("owner")).predefined?
  end

  test "a user may pick the predefined templates of their language and their own, not another game master's" do
    user = create_user("player")
    predefined_in_french = SheetTemplate.create!(name: "Fantasy", locale: "fr")
    predefined_in_english = SheetTemplate.create!(name: "Fantasy", locale: "en")
    own = SheetTemplate.create!(name: "Mon jeu", owner: user)
    someone_elses = SheetTemplate.create!(name: "Son jeu", owner: create_user("other"))

    available = SheetTemplate.available_to(user, locale: :fr)

    assert_includes available, predefined_in_french
    assert_includes available, own
    assert_not_includes available, predefined_in_english
    assert_not_includes available, someone_elses
  end

  test "the snapshot holds the definitions, not the ready-made characters" do
    sheet_template = SheetTemplate.new(
      name: "Fantasy",
      character_fields: { "fields" => [{ "key" => "strength", "type" => "number" }] },
      preset_characters: [{ "name" => "Gobelin" }]
    )

    snapshot = sheet_template.snapshot

    assert_equal [{ "key" => "strength", "type" => "number" }], snapshot.dig("character_fields", "fields")
    assert_not snapshot.key?("preset_characters")
    assert_not snapshot.key?("name")
  end

  test "deleting a template keeps the tables made from it" do
    sheet_template = SheetTemplate.create!(name: "Fantasy", locale: "fr")
    game_table = GameTable.create!(name: "Les Marches du Nord", sheet_template: sheet_template)

    sheet_template.destroy

    assert_nil game_table.reload.sheet_template_id
  end

  test "deleting an account deletes its own templates" do
    user = create_user("owner")
    SheetTemplate.create!(name: "Mon jeu", owner: user)

    assert_difference("SheetTemplate.count", -1) { user.destroy }
  end

  private

  def create_user(username)
    User.create!(email: "#{username}@example.com", username: username, password: TEST_PASSWORD)
  end
end
