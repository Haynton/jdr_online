require "test_helper"

class SheetTemplatesFieldUpdaterTest < ActiveSupport::TestCase
  setup do
    original = EquipmentSpellsTemplateBuilder.create_template
    game_master = User.create!(email: "mj@example.com", username: "Morgane", password: TEST_PASSWORD)
    @template = SheetTemplates::Duplicator.new(original: original, owner: game_master).call
  end

  test "each setting is converted by its kind; an empty one is taken out, an unticked box too" do
    assert update("level", label: "Niveau du héros", help: "", max: "15", required: "1", at_creation: "1",
                           section: "Notes")

    level = field("level")
    assert_equal "Niveau du héros", level["label"]
    assert_equal 15, level["max"]
    assert_equal true, level["required"]
    assert_not level.key?("help")
    assert_not level.key?("at_creation")
    assert_equal "number", level["type"]
  end

  test "an unticked asked at creation says false; a decimal step keeps its fraction, a round one is whole" do
    assert update("level", label: "Niveau", section: "Notes", at_creation: "0", step: "0,5")
    assert_equal false, field("level")["at_creation"]
    assert_in_delta 0.5, field("level")["step"]

    assert update("level", label: "Niveau", section: "Notes", at_creation: "1", step: "2")
    assert_equal 2, field("level")["step"]
  end

  test "the options are one per line, empty lines and repeats left out" do
    eyes = { "key" => "eyes", "label" => "Yeux", "type" => "choice", "options" => %w[Bleus], "section" => "Notes" }
    @template.update!(character_fields: @template.character_fields.merge(
      "fields" => @template.character_fields["fields"] + [eyes]
    ))

    assert update("eyes", label: "Yeux", section: "Notes", options: "Verts\r\n\r\nBruns\r\nVerts\r\n")
    assert_equal %w[Verts Bruns], field("eyes")["options"]
  end

  test "the key, the type and the options of a list with effects never change" do
    original_options = field("class")["options"]

    assert update("class", label: "Vocation", section: "Classe", options: "Barde", key: "job", type: "text")
    assert_equal "Vocation", field("class")["label"]
    assert_equal original_options, field("class")["options"]
    assert_equal "choice", field("class")["type"]
  end

  test "a value the template refuses is not saved and says why" do
    assert_not update("level", min: "10", max: "5")

    assert @template.errors.of_kind?(:base, :min_above_max)
    saved_level = @template.reload.character_fields["fields"].find { |candidate| candidate["key"] == "level" }
    assert_not_equal 10, saved_level["min"]
  end

  test "a whole number that is not one is refused" do
    assert_not update("level", max: "beaucoup")

    assert @template.errors.of_kind?(:base, :invalid_parameter_value)
  end

  private

  def update(field_key, **values)
    SheetTemplates::FieldUpdater.new(sheet_template: @template, field_key: field_key,
                                     submitted_values: values.transform_keys(&:to_s)).call
  end

  def field(key)
    @template.character_fields["fields"].find { |candidate| candidate["key"] == key }
  end
end
