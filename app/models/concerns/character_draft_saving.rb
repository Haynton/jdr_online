# Saving a step of a character being made in the background (autosave_controller.js), and putting back the values the
# validators refuse
module CharacterDraftSaving
  extend ActiveSupport::Concern

  # Saved in the background while the player fills a step (decision: nothing typed is lost, even when the tab closes):
  # what is valid is kept, a refused value keeps the one saved before (its error shows on Continue), and a required
  # field may stay empty in a draft. The step reached does not move
  def save_draft_step(step, sheet_values:, name: nil, **choices)
    saved_values = { sheet: sheet.deep_dup, name: self.name, spells: spells.deep_dup,
                     fighting_style: fighting_style, weapon_masteries: weapon_masteries.deep_dup }
    fill_step(step, sheet_values: sheet_values, name: name, **choices)
    self.required_sheet_fields = nil
    restore_refused_values(saved_values) if invalid?
    save
  end

  private

  # Each value refused by the validators goes back to the one saved before (a field of the sheet, the scores, the name,
  # the spells)
  def restore_refused_values(saved_values)
    errors.attribute_names.each do |attribute|
      next restore_ability_scores(saved_values[:sheet]) if attribute == :ability_scores

      field_key = attribute.to_s.delete_prefix("sheet.")
      next restore_sheet_value(field_key, saved_values[:sheet]) unless field_key == attribute.to_s

      self[attribute] = saved_values[attribute] if saved_values.key?(attribute)
    end
  end

  def restore_sheet_value(field_key, saved_sheet)
    return self.sheet = sheet.except(field_key) unless saved_sheet.key?(field_key)

    self.sheet = sheet.merge(field_key => saved_sheet[field_key])
  end
end
