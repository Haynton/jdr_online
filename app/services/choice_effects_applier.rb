# Applies to a sheet the effects of the options that changed in its lists (SheetTemplate::CHOICE_EFFECTS), the same
# way character_sheet_controller.js#applyEffects does on the page: the effects of the option picked before are
# taken back, those of the new one applied (decision: replaced). proficient: bonus fields unticked, then ticked;
# set: values written (speed, size), a field the option before had filled and the new one does not is emptied.
# Needed on the server since the creation is in steps: the background, on its step, ticks skills of another step.
# A list whose option did not change applies nothing: what the player changed by hand stays
class ChoiceEffectsApplier
  def initialize(fields:, previous_sheet:)
    @fields = fields
    @previous_sheet = previous_sheet.to_h
  end

  def call(sheet)
    @fields.select { |field| field["effects"] }.each_with_object(sheet.dup) do |field, applied_sheet|
      previous_option = @previous_sheet[field["key"]]
      picked_option = applied_sheet[field["key"]]
      next if previous_option == picked_option

      effects = field["effects"]
      replace_effects(applied_sheet, effects[previous_option.to_s].to_h, effects[picked_option.to_s].to_h)
    end
  end

  private

  def replace_effects(sheet, previous_effects, picked_effects)
    previous_effects["proficient"].to_a.each { |field_key| sheet[field_key] = false }
    picked_effects["proficient"].to_a.each { |field_key| sheet[field_key] = true }
    (previous_effects["set"].to_h.keys - picked_effects["set"].to_h.keys).each { |field_key| sheet.delete(field_key) }
    sheet.merge!(picked_effects["set"].to_h)
  end
end
