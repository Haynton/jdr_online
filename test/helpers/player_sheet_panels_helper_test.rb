require "test_helper"

# The panels of a player's sheet: the saving throws go into the tiles of the abilities (the section with one bonus per
# ability), the values of a fight beside the armour class, those of a caster apart for the panel « Sorts »
class PlayerSheetPanelsHelperTest < ActionView::TestCase
  include CharacterSheets::ValuesHelper

  SheetOwner = Struct.new(:sheet_fields, :sheet)

  ABILITIES = [{ "key" => "strength", "label" => "Force", "type" => "ability" },
               { "key" => "dexterity", "label" => "Dextérité", "type" => "ability" }].freeze
  FIELDS = ABILITIES + [
    { "key" => "strength_save", "label" => "Sauvegarde de Force", "type" => "bonus", "based_on" => "strength",
      "section" => "Jets de sauvegarde" },
    { "key" => "dexterity_save", "label" => "Sauvegarde de Dextérité", "type" => "bonus", "based_on" => "dexterity",
      "section" => "Jets de sauvegarde" },
    { "key" => "arcana", "label" => "Arcanes", "type" => "bonus", "based_on" => "dexterity",
      "section" => "Compétences" },
    { "key" => "stealth", "label" => "Discrétion", "type" => "bonus", "based_on" => "dexterity",
      "section" => "Compétences" },
    { "key" => "speed", "label" => "Vitesse (m)", "abbreviation" => "Vit. (m)", "type" => "number" },
    { "key" => "proficiency_bonus", "label" => "Bonus de maîtrise", "type" => "computed" },
    { "key" => "spell_save_dc", "label" => "DD des sorts", "type" => "computed" }
  ].freeze

  setup do
    @character = SheetOwner.new(FIELDS, { "strength_save" => true, "arcana" => true, "stealth" => false, "speed" => 9 })
    @sections = own_bonus_sections(@character)
  end

  test "the section with one bonus per ability goes into the tiles" do
    section, saves = own_tile_bonus_section(@sections, ABILITIES)

    assert_equal "Jets de sauvegarde", section
    assert_equal "strength_save", saves["strength"]["key"]
  end

  test "the values of a fight beside the armour class, none for a value the character has not" do
    stats = own_quick_stats(@character, { values: { "proficiency_bonus" => 2, "spell_save_dc" => nil } })

    shown = stats.map { |stat| [stat[:short_label], stat[:value]] }

    assert_equal [["Vit. (m)", "9"], ["Bonus de maîtrise", "+2"]], shown
  end

  test "the values of a caster are apart, for the panel of the spells" do
    stats = own_quick_stats(@character, { values: { "spell_save_dc" => "13" } },
                            keys: PlayerSheetPanelsHelper::SPELL_STAT_FIELD_KEYS)

    assert_equal([["DD des sorts", "13"]], stats.map { |stat| [stat[:short_label], stat[:value]] })
  end
end
