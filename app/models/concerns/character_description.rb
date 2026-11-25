# Who the character is, changed by its player once it is complete, from « Mes personnages » (decision: identity and
# description only). Its name and the fields that change nothing worked out (FieldTypes::Base#describes_character?: a
# text, a list without effects, the languages); the class, the abilities, the spells and the equipment stay as made
module CharacterDescription
  extend ActiveSupport::Concern

  def description_fields
    game_table.character_creation_fields.select { |field| FieldTypes.of(field).describes_character?(field) }
  end

  # Those fields only are replaced by what the player sent: an emptied one is removed, the rest of the sheet is kept
  def fill_description(name:, sheet_values:)
    fields = description_fields
    filled_values = CharacterSheets::Builder.new(fields: fields, submitted_values: sheet_values).call
    self.sheet = sheet.except(*fields.pluck("key")).merge(filled_values)
    self.name = name
  end
end
