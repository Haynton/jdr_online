require "test_helper"

class SheetTemplatesFieldUpdaterTest < ActiveSupport::TestCase
  setup do
    original = EquipmentSpellsTemplateBuilder.create_template
    game_master = User.create!(email: "mj@example.com", username: "Morgane", password: TEST_PASSWORD)
    @template = SheetTemplates::Duplicator.new(original: original, owner: game_master).call
  end

  test "each tuned setting is converted by its kind, an empty one taken out; the label and the build stay" do
    assert update("level", label: "Niveau du héros", help: "", max: "15", required: "1", at_creation: "0",
                           section: "Combat", from_table: "")

    level = field("level")
    assert_equal "Niveau", level["label"]
    assert_equal 15, level["max"]
    assert_not level.key?("help")
    assert_equal ["Notes", "starting_level"], level.values_at("section", "from_table")
    assert_not level.key?("required")
    assert_not level.key?("at_creation")
    assert_equal "number", level["type"]
  end

  test "a step is tuned only where the field has one; a decimal keeps its fraction, a round one is whole" do
    assert update("level", step: "0,5")
    assert_not field("level").key?("step")

    with_level_step(1)
    assert update("level", step: "0,5")
    assert_in_delta 0.5, field("level")["step"]

    assert update("level", step: "2")
    assert_equal 2, field("level")["step"]
  end

  test "the options are one per line, empty lines and repeats left out" do
    eyes = { "key" => "eyes", "label" => "Yeux", "type" => "choice", "options" => %w[Bleus], "section" => "Notes" }
    @template.update!(character_fields: @template.character_fields.merge(
      "fields" => @template.character_fields["fields"] + [eyes]
    ))

    assert update("eyes", label: "Yeux", options: "Verts\r\n\r\nBruns\r\nVerts\r\n")
    assert_equal %w[Verts Bruns], field("eyes")["options"]
  end

  test "the key, the type and the options of a list with effects never change" do
    original_options = field("class")["options"]

    assert update("class", help: "Votre vocation", options: "Barde", key: "job", type: "text")
    assert_equal "Votre vocation", field("class")["help"]
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

  def with_level_step(step)
    fields = @template.character_fields["fields"].map do |candidate|
      candidate["key"] == "level" ? candidate.merge("step" => step) : candidate
    end
    @template.update!(character_fields: @template.character_fields.merge("fields" => fields))
  end

  def update(field_key, **values)
    SheetTemplates::FieldUpdater.new(sheet_template: @template, field_key: field_key,
                                     submitted_values: values.transform_keys(&:to_s)).call
  end

  def field(key)
    @template.character_fields["fields"].find { |candidate| candidate["key"] == key }
  end
end
