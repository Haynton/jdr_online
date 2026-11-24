require "test_helper"

# The registry of the field types (FieldTypes): the types it knows, and for each one how a typed value becomes a value
# of the sheet and how that value is checked
class FieldTypesTest < ActiveSupport::TestCase
  KEYS = %w[
    number resource ability ability_bonuses boolean text choice picks experience attacks bonus computed equipment_option
  ].freeze

  test "the registry knows the 13 types, in order, and finds a type by its key" do
    assert_equal KEYS, FieldTypes.keys
    assert_instance_of FieldTypes::Resource, FieldTypes.find("resource")
    assert_nil FieldTypes.find("vehicle")
  end

  test "an unknown type refuses any value, so that a key the template does not declare is refused" do
    assert_equal [:invalid], FieldTypes.of({ "type" => "vehicle" }).error_for("x", {})
    assert_equal [:invalid], FieldTypes.of(nil).error_for("x", nil)
  end

  test "a number with labels is a list of those names, its value still the number" do
    level = { "key" => "level", "type" => "number", "min" => 0, "max" => 2,
              "labels" => ["Sort mineur", "Niveau 1", "Niveau 2"] }
    type = FieldTypes.of(level)

    assert_equal [["Sort mineur", 0], ["Niveau 1", 1], ["Niveau 2", 2]], type.list_choices(level)
    assert_equal FieldTypes::Base::INPUT_PARTIAL, type.partial_for(level)
    assert_equal :lists, type.flow_group(level)
    assert_equal "Niveau 1", type.summary_text(1, level)
    assert_equal 1, type.convert("1", level)
    assert_nil type.list_choices(level.except("labels"))
    assert_equal "character_sheets/fields/stat", type.partial_for(level.except("labels"))
  end

  test "every partial a type declares exists" do
    FieldTypes.all.filter_map(&:partial).uniq.each do |partial|
      directory, name = File.split(partial)
      assert_path_exists Rails.root.join("app/views/#{directory}/_#{name}.html.erb"), partial
    end
  end

  test "the provided templates use only types of the registry" do
    Rails.root.glob("db/seeds/sheet_templates/*.json").each do |template_file|
      template = JSON.parse(template_file.read(encoding: "UTF-8"))
      types = %w[character_fields npc_fields item_fields spell_fields].flat_map do |definition|
        template.dig(definition, "fields").to_a.pluck("type")
      end
      assert_empty types.uniq - FieldTypes.keys, template_file.basename.to_s
    end
  end

  test "a number is an integer within its bounds, or a multiple of a step under 1" do
    number = FieldTypes.find("number")
    field = { "min" => 1, "max" => 20 }

    assert_equal 12, number.convert(" 12 ", field)
    assert_equal "douze", number.convert("douze", field)
    assert_equal 10.5, number.convert("10,5", { "step" => 0.5 })
    assert_nil number.error_for(12, field)
    assert_equal [:greater_than_or_equal_to, { count: 1 }], number.error_for(0, field)
    assert_equal [:less_than_or_equal_to, { count: 20 }], number.error_for(21, field)
    assert_equal [:not_an_integer], number.error_for("douze", field)
    assert_equal [:invalid], number.error_for(10.25, { "step" => 0.5 })
  end

  test "a resource is typed by its maximum and starts full" do
    resource = FieldTypes.find("resource")

    assert_equal({ "current" => 9, "max" => 9 }, resource.convert("9", {}))
    assert_nil resource.error_for({ "current" => 4, "max" => 9 }, {})
    assert_equal [:invalid], resource.error_for({ "current" => 10, "max" => 9 }, {})
    assert_equal({ "current" => 7, "max" => 7 }, resource.initial_value(7))
    assert_equal "game_tables.characters.new.resource_hint", resource.fixed_hint
  end

  test "a check box keeps its value unticked: a yes-or-no value and the proficiency of a bonus" do
    %w[boolean bonus].each do |key|
      type = FieldTypes.find(key)

      assert_not type.blank?("0"), key
      assert_equal [true, false], [type.convert("1", {}), type.convert("0", {})], key
      assert_equal [:inclusion], type.error_for("yes", {}), key
    end
  end

  test "a choice is one of its options, picks several of them, count at most" do
    field = { "options" => %w[Elfique Nain Orc], "count" => 2, "granted" => ["Commun"] }

    assert_nil FieldTypes.find("choice").error_for("Nain", field)
    assert_equal [:inclusion], FieldTypes.find("choice").error_for("Gobelin", field)
    assert_equal %w[Elfique Nain], FieldTypes.find("picks").convert(["", "Elfique", "Nain"], field)
    assert_equal [:too_many_picks, { count: 2 }], FieldTypes.find("picks").error_for(%w[Elfique Nain Orc], field)
    I18n.with_locale(:fr) do
      assert_equal "Commun et Elfique", FieldTypes.find("picks").summary_text(["Elfique"], field)
    end
  end

  test "attacks are lines of name, bonus to hit, damage and range, the blank lines left out" do
    attacks = FieldTypes.find("attacks")
    typed = { "0" => { "name" => " Cimeterre ", "to_hit" => "+4", "damage" => "1d6+2 tranchants", "range" => "" },
              "1" => { "name" => "", "to_hit" => "", "damage" => "", "range" => "" } }

    assert_equal [{ "name" => "Cimeterre", "to_hit" => 4, "damage" => "1d6+2 tranchants" }], attacks.convert(typed, {})
    assert_equal [], attacks.convert(nil, {})
    assert_nil attacks.error_for([{ "name" => "Morsure", "to_hit" => -1 }], {})
    assert_equal [:attack_without_name], attacks.error_for([{ "to_hit" => 4 }], {})
    assert_equal [:attack_bonus_not_integer], attacks.error_for(attacks.convert({ "0" => { "name" => "Arc", "to_hit" => "quatre" } }, {}), {})
    assert_equal [:too_many_attacks, { count: 20 }], attacks.error_for(Array.new(21) { { "name" => "Griffe" } }, {})
  end

  test "a text is checked by its length, and a short one reads with the facts" do
    text = FieldTypes.find("text")

    assert_equal [:too_long, { count: FieldTypes::Text::MAX_LENGTH }], text.error_for("a" * 2001, {})
    assert_equal :lists, text.flow_group({ "short" => true })
    assert_equal :texts, text.summary_group({})
  end

  test "a computed value is never stored, and the bonus and equipment are drawn by their own section or step" do
    assert_not FieldTypes.find("computed").stored?
    assert_nil FieldTypes.find("ability_bonuses").partial
    assert_nil FieldTypes.find("equipment_option").summary_group({})
  end

  test "an equipment option keeps only the picks of the option chosen, and is blank without an option" do
    equipment = FieldTypes.find("equipment_option")
    typed_value = { "option" => "a", "picks" => { "a" => { "2" => "lute" }, "b" => { "1" => "flute" } } }

    assert_equal({ "option" => "a", "picks" => { "2" => "lute" } }, equipment.convert(typed_value, {}))
    assert equipment.blank?({ "picks" => { "a" => { "2" => "lute" } } })
  end
end
