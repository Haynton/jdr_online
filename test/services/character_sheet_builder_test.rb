require "test_helper"

class CharacterSheetBuilderTest < ActiveSupport::TestCase
  FIELDS = [
    { "key" => "strength", "type" => "number" },
    { "key" => "experience", "type" => "experience" },
    { "key" => "hp", "type" => "resource" },
    { "key" => "inspiration", "type" => "boolean" },
    { "key" => "class", "type" => "choice" },
    { "key" => "background", "type" => "text" }
  ].freeze

  test "the typed values become the values of the sheet, by field type" do
    sheet = build_sheet("strength" => "12", "experience" => "300", "hp" => "8", "inspiration" => "1",
                        "class" => "Mage", "background" => "  Né sous la lune ")

    assert_equal({ "strength" => 12, "experience" => 300, "hp" => { "current" => 8, "max" => 8 },
                   "inspiration" => true, "class" => "Mage", "background" => "Né sous la lune" }, sheet)
  end

  test "a blank field is left out, an unchecked box is false" do
    assert_equal({ "inspiration" => false }, build_sheet("strength" => "", "hp" => " ", "inspiration" => "0"))
  end

  test "a value that is not a number is kept as typed, for the validator to refuse it" do
    assert_equal({ "strength" => "fort", "hp" => "plein", "inspiration" => false },
                 build_sheet("strength" => "fort", "hp" => "plein"))
  end

  test "a bonus keeps only its proficiency, a computed field is never stored" do
    fields = [{ "key" => "athletics", "type" => "bonus" }, { "key" => "proficiency_bonus", "type" => "computed" }]
    sheet = CharacterSheetBuilder.new(fields: fields,
                                      submitted_values: { "athletics" => "1", "proficiency_bonus" => "6" }).call

    assert_equal({ "athletics" => true }, sheet)
  end

  test "a key that is not a field of the template is ignored" do
    assert_equal({ "inspiration" => false }, build_sheet("luck" => "3"))
  end

  private

  def build_sheet(submitted_values)
    CharacterSheetBuilder.new(fields: FIELDS, submitted_values: submitted_values).call
  end
end
