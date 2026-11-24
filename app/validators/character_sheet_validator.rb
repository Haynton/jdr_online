# Checks the values of a character sheet (a player character, an NPC, a monster) against the fields of the template
# copied into its table (Character#sheet_fields), each by the check of its type (FieldTypes): JSONB has no check of its
# own in the database. A wrong value gets its error on "sheet.<key of the field>", shown under that field of the form
class CharacterSheetValidator < ActiveModel::Validator
  def validate(character)
    return unless character.game_table

    fields_by_key = character.sheet_fields.index_by { |field| field["key"] }
    character.sheet.each do |key, value|
      field = fields_by_key[key]
      error_type, error_options = FieldTypes.of(field).error_for(value, field, character: character)
      character.errors.add(:"sheet.#{key}", error_type, **error_options.to_h) if error_type
    end
    validate_required_fields(character)
  end

  private

  # The fields marked required in the step being saved (Character#fill_step): the step stays until they are filled.
  # A field the sheet does not ask yet (the subclass, before level 3) waits
  def validate_required_fields(character)
    character.required_sheet_fields.to_a.each do |field|
      next unless FieldTypes.of(field).asked_on?(field, character.sheet)

      character.errors.add(:"sheet.#{field['key']}", :blank) if character.sheet[field["key"]].blank?
    end
  end
end
