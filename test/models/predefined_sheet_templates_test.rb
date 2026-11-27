require "test_helper"

# The predefined templates are written by hand in db/seeds/sheet_templates: these tests read the files. The shape of
# a template (keys, types, settings, rules, effects, steps) is checked by SheetTemplateValidator, through valid?; here
# stays what one template alone cannot say (its other language) and what the heroic fantasy is expected to give
class PredefinedSheetTemplatesTest < ActiveSupport::TestCase
  TEMPLATES_DIRECTORY = Rails.root.join("db/seeds/sheet_templates")
  TEMPLATE_FILES = TEMPLATES_DIRECTORY.glob("*.json").sort
  # spell_fields: only the templates that have spells (not the cosmic horror)
  FIELD_DEFINITIONS = %w[character_fields npc_fields item_fields spell_fields].freeze
  # The conditions of the SRD 5.2.1 (Rules Glossary), in its order
  SRD_CONDITION_KEYS = %w[
    blinded charmed deafened exhaustion frightened grappled incapacitated invisible paralyzed petrified poisoned
    prone restrained stunned unconscious
  ].freeze

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

  test "the classes of a spell are the options of the class list of the sheet" do
    each_template do |template_file, template|
      spell_classes = template.dig("spell_fields", "fields").to_a.find { |field| field["key"] == "classes" }
      next unless spell_classes

      class_list = template.dig("character_fields", "fields").find { |field| field["key"] == "class" }
      assert_equal class_list["options"].sort, spell_classes["options"].sort, template_file.basename.to_s
    end
  end

  test "the levels give the proficiency bonus that the rule proficiency_by_level reads" do
    each_template do |template_file, template|
      computed_fields = template.dig("character_fields", "fields").select { |field| field["type"] == "computed" }
      next if computed_fields.none? { |field| field["rule"] == "proficiency_by_level" }

      assert template["level_thresholds"].all? { |threshold| threshold["proficiency_bonus"].is_a?(Integer) },
             "#{template_file.basename}: every level needs its proficiency_bonus"
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

  test "the heroic fantasy names its hero on a first step of its own, with its sentence, in both languages" do
    %w[fr en].each do |language|
      steps = read_template(TEMPLATES_DIRECTORY.join("heroic_fantasy.#{language}.json")).dig("character_fields",
                                                                                             "creation_steps")

      assert_equal "identity", steps.first["key"]
      assert steps.first["asks_name"]
      assert_empty steps.first["sections"]
      assert_predicate steps.first["intro"], :present?
      assert_equal(1, steps.count { |step| step["asks_name"] })
    end
  end

  test "the heroic fantasy picks its class, background and species among cards with an emblem, in both languages" do
    %w[fr en].each do |language|
      template = read_template(TEMPLATES_DIRECTORY.join("heroic_fantasy.#{language}.json"))

      fields = template.dig("character_fields", "fields").index_by { |field| field["key"] }
      %w[class background species].each do |key|
        assert_equal fields[key]["options"].sort, fields[key]["icons"].keys.sort, "#{language} #{key}"
      end
      assert_equal %w[identity class origin], template.dig("character_fields", "creation_steps").first(3).pluck("key")
    end
  end

  # The table of the SRD 5.2.1: full casters, half casters (from level 1 in 2024), and the pact slots of the warlock,
  # all of one level
  test "the heroic fantasy declares the 15 conditions of the SRD 5.2.1, the same in both languages" do
    conditions = %w[fr en].map do |locale|
      read_template(TEMPLATES_DIRECTORY.join("heroic_fantasy.#{locale}.json"))["character_fields"]["conditions"]
    end

    assert_equal SRD_CONDITION_KEYS, conditions.first.pluck("key")
    conditions.each do |declared|
      assert_equal conditions.first.pluck("key", "levels"), declared.pluck("key", "levels")
      assert(declared.all? { |condition| condition["description"].present? })
    end
    assert_equal 6, conditions.first.find { |condition| condition["key"] == "exhaustion" }["levels"]
  end

  MODE_RULES = %w[key dice keep].freeze

  test "the heroic fantasy rolls with advantage, disadvantage and a d20 of initiative, the same in both languages" do
    dice_rolls = %w[fr en].map do |locale|
      read_template(TEMPLATES_DIRECTORY.join("heroic_fantasy.#{locale}.json"))["character_fields"]["dice_rolls"]
    end

    assert_equal %w[advantage disadvantage], dice_rolls.first["modes"].pluck("key")
    dice_rolls.each do |declared|
      assert_equal dice_rolls.first["modes"].pluck(*MODE_RULES), declared["modes"].pluck(*MODE_RULES)
      assert_equal dice_rolls.first["initiative"].except("label"), declared["initiative"].except("label")
    end
  end

  test "the spell slots of the 2024 heroic fantasy follow the levels of each class" do
    classes = heroic_fantasy_classes

    assert_equal [[2], [4, 3, 2], [4, 3, 3, 3, 3, 2, 2, 1, 1]], slots_at(classes["Magicien"], 1, 5, 20)
    assert_equal [[2], [4, 2], [4, 3, 3, 3, 2]], slots_at(classes["Paladin"], 1, 5, 20)
    assert_equal [[1], [0, 0, 2], [0, 0, 0, 0, 4]], slots_at(classes["Occultiste"], 1, 5, 20)
    assert_equal "Emplacements de pacte", classes["Occultiste"].dig("spellcasting", "slots_label")
    classes.values.filter_map { |effects| effects["spellcasting"] }.each do |spellcasting|
      assert_equal spellcasting["max_spell_level"], spellcasting["slots"].map(&:size), "slots up to the highest level"
    end
  end

  test "every class of the heroic fantasy has its subclass of the SRD 5.2.1, asked from level 3" do
    %w[fr en].each do |locale|
      template = read_template(TEMPLATES_DIRECTORY.join("heroic_fantasy.#{locale}.json"))
      fields = template.dig("character_fields", "fields").index_by { |field| field["key"] }
      subclass = fields["subclass"]

      assert_equal fields["class"]["options"].sort, subclass["options_by"].keys.sort, locale
      assert(subclass["options_by"].values.all? { |options| options.size == 1 }, locale)
      assert_equal [3, "level"], subclass.values_at("from_level", "level_from"), locale
      assert_equal subclass["options"].sort, subclass["descriptions"].keys.sort, locale
      assert(subclass["effects"].values.all? { |effects| effects["features_by_level"].key?("3") }, locale)
    end
  end

  private

  def heroic_fantasy_classes
    template = read_template(TEMPLATES_DIRECTORY.join("heroic_fantasy.fr.json"))
    template.dig("character_fields", "fields").find { |field| field["key"] == "class" }["effects"]
  end

  def slots_at(class_effects, *levels)
    levels.map { |level| class_effects.dig("spellcasting", "slots", level - 1) }
  end

  def each_template
    TEMPLATE_FILES.each { |template_file| yield template_file, read_template(template_file) }
  end

  def read_template(template_file)
    JSON.parse(template_file.read(encoding: "UTF-8"))
  end

  # Sorted: each language lists the skills in the alphabetical order of their own labels
  def field_keys_of(template)
    FIELD_DEFINITIONS.to_h { |definition| [definition, template.dig(definition, "fields").to_a.pluck("key").sort] }
  end
end
