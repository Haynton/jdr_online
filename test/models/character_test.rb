require "test_helper"

class CharacterTest < ActiveSupport::TestCase
  SHEET_FIELDS = [
    { "key" => "class", "label" => "Classe", "type" => "choice", "options" => %w[Mage Guerrier] },
    { "key" => "strength", "label" => "Force", "type" => "number", "min" => 1, "max" => 20 },
    { "key" => "hp", "label" => "PV", "type" => "resource" },
    { "key" => "inspiration", "label" => "Inspiration", "type" => "boolean" },
    { "key" => "experience", "label" => "Expérience", "type" => "experience" },
    { "key" => "background", "label" => "Histoire", "type" => "text" }
  ].freeze

  setup do
    @game_table = GameTable.create!(name: "La Crypte",
                                    template_snapshot: { "character_fields" => { "fields" => SHEET_FIELDS } })
    player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD)
    @participation = @game_table.participations.create!(user: player, role: :player)
  end

  test "a player character with a sheet that fits the template is valid" do
    sheet = { "class" => "Mage", "strength" => 12, "hp" => { "current" => 8, "max" => 8 }, "inspiration" => false,
              "experience" => 0, "background" => "Né sous la lune" }

    assert build_character(sheet: sheet).valid?
  end

  test "a character needs a name of 60 characters at most" do
    assert_not build_character(name: "").valid?
    assert_not build_character(name: "a" * 61).valid?
  end

  test "a player character belongs to a participation, and a player has only one per table" do
    assert build_character(participation: nil).tap(&:validate).errors.of_kind?(:participation, :blank)

    build_character.save!
    second_character = build_character(name: "Bertrand")
    errors = second_character.tap(&:validate).errors
    # message: :already_has_character changes the text of the uniqueness error, not its kind (:taken)
    assert errors.of_kind?(:participation_id, :taken)
    assert_includes errors[:participation_id], "already has a character at this table"
  end

  test "a number outside the bounds of its field is refused, under that field" do
    errors = build_character(sheet: { "strength" => 25 }).tap(&:validate).errors

    assert errors.of_kind?(:'sheet.strength', :less_than_or_equal_to)
  end

  test "a value of the wrong type is refused" do
    errors = build_character(sheet: { "strength" => "fort", "class" => "Barde", "inspiration" => "oui",
                                      "hp" => "plein" }).tap(&:validate).errors

    assert errors.of_kind?(:'sheet.strength', :not_an_integer)
    assert errors.of_kind?(:'sheet.class', :inclusion)
    assert errors.of_kind?(:'sheet.inspiration', :inclusion)
    assert errors.of_kind?(:'sheet.hp', :not_an_integer)
  end

  test "a bonus stores a proficiency, ticked or not, and a computed value is never stored" do
    fields = [
      { "key" => "athletics", "type" => "bonus", "based_on" => "strength", "proficiency" => "proficiency_bonus" },
      { "key" => "proficiency_bonus", "type" => "computed", "rule" => "proficiency_by_level" }
    ]
    @game_table.update!(template_snapshot: { "character_fields" => { "fields" => fields } })

    assert build_character(sheet: { "athletics" => true }).valid?
    errors = build_character(sheet: { "athletics" => 3, "proficiency_bonus" => 2 }).tap(&:validate).errors
    assert errors.of_kind?(:'sheet.athletics', :inclusion)
    assert errors.of_kind?(:'sheet.proficiency_bonus', :invalid)
  end

  test "a key that is not a field of the template is refused" do
    assert build_character(sheet: { "luck" => 3 }).tap(&:validate).errors.of_kind?(:'sheet.luck', :invalid)
  end

  test "a character goes away with its participation" do
    build_character.save!

    assert_difference("Character.count", -1) { @participation.destroy }
  end

  private

  def build_character(name: "Aldric", sheet: {}, participation: @participation)
    Character.new(game_table: @game_table, participation: participation, kind: :pc, name: name, sheet: sheet)
  end
end
