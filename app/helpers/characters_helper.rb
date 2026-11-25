# The page « Mes personnages » and the sheet of one character (CharactersController)
module CharactersHelper
  # A complete character opens its sheet; a draft goes back to its creation steps, at the step reached
  def character_card_path(character)
    return new_game_table_character_path(character.game_table) if character.draft?

    character_path(character)
  end

  # Its main choices on its card, in the words of the template ("Rôdeur · Criminel · Elfe"): the lists whose options
  # act on the sheet (the class, the background, the species), those filled in
  def character_card_choices(character)
    character.sheet_fields.select { |field| field["effects"].present? }.filter_map do |field|
      value = character.sheet[field["key"]]
      FieldTypes.of(field).summary_text(value, field) if value.present?
    end.join(" · ")
  end

  def character_display_name(character)
    character.name.presence || t("game_tables.character_steps.summary.unnamed")
  end
end
