require "test_helper"

# The predefined templates are written by hand in db/seeds/sheet_templates: these tests read the files
# and check that they follow the format of the design notes ("Base de données", the template builder)
class PredefinedSheetTemplatesTest < ActiveSupport::TestCase
  TEMPLATES_DIRECTORY = Rails.root.join("db/seeds/sheet_templates")
  TEMPLATE_FILES = TEMPLATES_DIRECTORY.glob("*.json").sort
  FIELD_DEFINITIONS = %w[character_fields npc_fields item_fields].freeze

  test "every file makes a valid predefined template" do
    each_template do |template_file, template|
      sheet_template = SheetTemplate.new(template)

      assert sheet_template.valid?, "#{template_file.basename}: #{sheet_template.errors.full_messages.to_sentence}"
      assert sheet_template.predefined?
    end
  end

  test "every template exists in every language of the app" do
    template_names = TEMPLATE_FILES.map { |template_file| template_file.basename.to_s.split(".").first }.uniq

    template_names.each do |template_name|
      I18n.available_locales.each do |locale|
        assert_predicate Rails.root.join("db/seeds/sheet_templates/#{template_name}.#{locale}.json"), :exist?
      end
    end
  end

  test "the languages of a template share the same fields: only the texts change" do
    TEMPLATE_FILES.group_by { |template_file| template_file.basename.to_s.split(".").first }.each_value do |versions|
      field_keys = versions.map { |template_file| field_keys_of(read_template(template_file)) }

      assert_equal 1, field_keys.uniq.size, "#{versions.map(&:basename).join(', ')} do not share the same fields"
    end
  end

  test "every field has a unique key and a known type" do
    each_template do |template_file, template|
      FIELD_DEFINITIONS.each do |definition|
        fields = template.dig(definition, "fields")
        keys = fields.pluck("key")

        assert_equal keys.uniq, keys, "#{template_file.basename}: #{definition} has a key twice"
        assert_empty fields.pluck("type") - SheetTemplate::FIELD_TYPES, "#{template_file.basename}: unknown type"
        modifier_rules = fields.select { |field| field["type"] == "ability" }.pluck("modifier")
        assert_empty modifier_rules - SheetTemplate::MODIFIER_RULES, "#{template_file.basename}: unknown modifier"
      end
    end
  end

  test "the damage settings point to a resource that exists" do
    each_template do |template_file, template|
      fields = template.dig("character_fields", "fields")
      resource_keys = fields.select { |field| field["type"] == "resource" }.pluck("key")

      assert_operator fields.count { |field| field["receives_damage"] }, :<=, 1, template_file.basename.to_s
      fields.filter_map { |field| field["absorbs_damage_for"] }.each do |absorbed_key|
        assert_includes resource_keys, absorbed_key, template_file.basename.to_s
      end
    end
  end

  test "a bonus or an ability modifier is based on an ability, a proficiency is a computed field" do
    each_template do |template_file, template|
      fields = template.dig("character_fields", "fields")
      ability_keys = fields.select { |field| field["type"] == "ability" }.pluck("key")
      computed_keys = fields.select { |field| field["type"] == "computed" }.pluck("key")

      fields.select { |field| field["type"] == "bonus" || field["rule"] == "ability_modifier" }.each do |field|
        assert_includes ability_keys, field["based_on"], "#{template_file.basename}: #{field['key']}"
      end
      fields.select { |field| field["type"] == "bonus" }.each do |bonus|
        assert_includes computed_keys, bonus["proficiency"], "#{template_file.basename}: #{bonus['key']}"
      end
    end
  end

  test "a computed field uses a known rule, and the levels give what the rule needs" do
    each_template do |template_file, template|
      computed_fields = template.dig("character_fields", "fields").select { |field| field["type"] == "computed" }

      computed_fields.each do |field|
        assert_includes SheetTemplate::COMPUTED_RULES, field["rule"], template_file.basename.to_s
      end
      proficiency_fields = computed_fields.select { |field| field["rule"] == "proficiency_by_level" }
      next if proficiency_fields.none?

      assert template["level_thresholds"].all? { |threshold| threshold["proficiency_bonus"].is_a?(Integer) },
             "#{template_file.basename}: every level needs its proficiency_bonus"
      number_keys = template.dig("character_fields", "fields").select { |field| field["type"] == "number" }.pluck("key")
      proficiency_fields.each do |field|
        assert_includes number_keys, field["level_from"], "#{template_file.basename}: level_from of #{field['key']}"
      end
    end
  end

  test "the effects of a list are known, for its own options, and name fields that exist" do
    each_template do |template_file, template|
      fields = template.dig("character_fields", "fields")
      fields.select { |field| field["effects"] }.each do |field|
        assert_empty field["effects"].keys - field["options"], "#{template_file.basename}: options of #{field['key']}"
        field["effects"].each do |option, effects|
          assert_known_effects(effects, fields, "#{template_file.basename}: #{option}")
        end
      end
    end
  end

  test "every field asked at creation belongs to a step, and every step to sections of the sheet" do
    each_template do |template_file, template|
      steps = template.dig("character_fields", "creation_steps")
      next unless steps

      fields = template.dig("character_fields", "fields")
      asked = fields.reject { |field| field["at_creation"] == false || field["from_table"] }
      step_sections = steps.flat_map { |step| step["sections"] }
      assert_empty asked.pluck("section").uniq - step_sections, "#{template_file.basename}: sections without a step"
      assert_empty step_sections - fields.pluck("section"), "#{template_file.basename}: steps without fields"
      assert_equal 1, steps.count { |step| step["asks_name"] }, "#{template_file.basename}: one step asks the name"
    end
  end

  test "the rules that read the class point to a list whose every option gives its hit die" do
    each_template do |template_file, template|
      fields = template.dig("character_fields", "fields")
      fields.select { |field| field["class_from"] }.each do |computed|
        class_field = fields.find { |field| field["key"] == computed["class_from"] }

        assert_equal "choice", class_field&.dig("type"), "#{template_file.basename}: class_from of #{computed['key']}"
        assert class_field["options"].all? { |option| class_field.dig("effects", option, "hit_die").is_a?(Integer) },
               "#{template_file.basename}: every class needs its hit_die"
      end
    end
  end

  test "the 2024 heroic fantasy gives its classes, backgrounds and species their effects" do
    template = read_template(TEMPLATES_DIRECTORY.join("heroic_fantasy.fr.json"))
    fields = template.dig("character_fields", "fields").index_by { |field| field["key"] }

    assert_equal 12, fields["class"]["effects"].size
    assert_equal %w[Acolyte Criminel Sage Soldat], fields["background"]["options"]
    assert_equal 9, fields["species"]["effects"].size
    assert_equal({ "speed" => 10.5, "size" => "Moyenne" }, fields["species"]["effects"]["Goliath"]["set"])
    wizard = fields["class"]["effects"]["Magicien"]
    assert_includes wizard.dig("skill_choices", "from"), "nature"
    assert_equal [3, 4, 1], wizard["spellcasting"].values_at("cantrips", "prepared", "max_spell_level").map(&:first)
  end

  test "the ready-made characters only fill fields of the NPC sheet, in the shape of their type" do
    each_template do |template_file, template|
      field_types = template.dig("npc_fields", "fields").to_h { |field| [field["key"], field["type"]] }

      template["preset_characters"].each do |preset_character|
        assert_includes %w[npc monster], preset_character["kind"]
        preset_character["sheet"].each do |key, value|
          context = "#{template_file.basename}: #{preset_character['name']}, #{key}"

          assert field_types.key?(key), context
          assert value_matches_type?(value, field_types[key]), context
        end
      end
    end
  end

  test "the ready-made items only fill fields of the item sheet" do
    each_template do |template_file, template|
      item_keys = template.dig("item_fields", "fields").pluck("key")

      template["preset_items"].each do |preset_item|
        assert_empty preset_item["properties"].keys - item_keys, "#{template_file.basename}: #{preset_item['name']}"
      end
    end
  end

  private

  def each_template
    TEMPLATE_FILES.each { |template_file| yield template_file, read_template(template_file) }
  end

  def read_template(template_file)
    JSON.parse(template_file.read(encoding: "UTF-8"))
  end

  # Sorted: each language lists the skills in the alphabetical order of their own labels
  def field_keys_of(template)
    FIELD_DEFINITIONS.to_h { |definition| [definition, template.dig(definition, "fields").pluck("key").sort] }
  end

  # Effects of SheetTemplate::CHOICE_EFFECTS only, naming fields of the sheet of the right type
  def assert_known_effects(effects, fields, context)
    keys_of_type = ->(type) { fields.select { |field| field["type"] == type }.pluck("key") }
    assert_empty effects.keys - SheetTemplate::CHOICE_EFFECTS, context
    assert_empty effects["proficient"].to_a - keys_of_type.call("bonus"), "#{context}: proficient"
    assert_empty effects["ability_bonus_choices"].to_a - keys_of_type.call("ability"), "#{context}: ability bonus"
    assert_empty effects["set"].to_h.keys - fields.pluck("key"), "#{context}: set"
    assert_skill_choices(effects["skill_choices"], keys_of_type.call("bonus"), context) if effects["skill_choices"]
    assert_spellcasting(effects["spellcasting"], keys_of_type.call("ability"), context) if effects["spellcasting"]
  end

  def assert_skill_choices(skill_choices, bonus_keys, context)
    assert_empty skill_choices["from"] - bonus_keys, "#{context}: skill_choices"
    assert_includes 1..skill_choices["from"].size, skill_choices["count"], "#{context}: count of skill_choices"
  end

  # One value per level, from 1 to 20
  def assert_spellcasting(spellcasting, ability_keys, context)
    assert_includes ability_keys, spellcasting["ability"], "#{context}: spellcasting ability"
    %w[cantrips prepared max_spell_level].each do |table|
      assert_equal 20, spellcasting[table].size, "#{context}: #{table}"
      assert spellcasting[table].all?(Integer), "#{context}: #{table}"
    end
  end

  # One shape per type (design notes, "Valeurs d'une fiche")
  def value_matches_type?(value, type)
    case type
    when "number", "ability" then value.is_a?(Hash) && value["value"].is_a?(Numeric)
    when "resource" then value.is_a?(Hash) && value.keys.sort == %w[current max]
    when "attacks" then value.is_a?(Array)
    when "boolean" then [true, false].include?(value)
    else value.is_a?(String)
    end
  end
end
