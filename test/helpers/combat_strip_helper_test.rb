require "test_helper"

# The panel « Ma fiche » of a player shows the saving throws and skills they are proficient in: the bonus fields
# ticked on their sheet, by the section of the template
class CombatStripHelperTest < ActionView::TestCase
  SheetOwner = Struct.new(:sheet_fields, :sheet)

  FIELDS = [
    { "key" => "strength_save", "label" => "Sauvegarde de Force", "type" => "bonus",
      "section" => "Jets de sauvegarde" },
    { "key" => "arcana", "label" => "Arcanes", "type" => "bonus", "section" => "Compétences" },
    { "key" => "stealth", "label" => "Discrétion", "type" => "bonus", "section" => "Compétences" },
    { "key" => "inspiration", "label" => "Inspiration", "type" => "boolean", "section" => "Combat" }
  ].freeze

  test "only the bonus fields ticked, by section, in the order of the template" do
    character = SheetOwner.new(FIELDS, { "strength_save" => true, "arcana" => true, "stealth" => false,
                                         "inspiration" => true })

    sections = own_proficiency_sections(character).transform_values { |fields| fields.pluck("label") }

    assert_equal({ "Jets de sauvegarde" => ["Sauvegarde de Force"], "Compétences" => ["Arcanes"] }, sections)
  end
end
