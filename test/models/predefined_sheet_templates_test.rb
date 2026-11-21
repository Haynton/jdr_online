require "test_helper"

# The predefined templates are written by hand in db/seeds/sheet_templates: these tests read the files
# and check that they follow the format of the design notes ("Base de données", the template builder)
class PredefinedSheetTemplatesTest < ActiveSupport::TestCase
  TEMPLATE_FILES = Rails.root.glob("db/seeds/sheet_templates/*.json").sort
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

  # One shape per type (design notes, "Valeurs d'une fiche")
  def value_matches_type?(value, type)
    case type
    when "number" then value.is_a?(Hash) && value["value"].is_a?(Numeric)
    when "resource" then value.is_a?(Hash) && value.keys.sort == %w[current max]
    when "attacks" then value.is_a?(Array)
    when "boolean" then [true, false].include?(value)
    else value.is_a?(String)
    end
  end
end
