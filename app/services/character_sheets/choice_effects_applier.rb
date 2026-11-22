# Applies to a sheet the effects of the options that changed in its lists, each effect doing its part (ChoiceEffects:
# proficient ticks, set writes, ability_bonus_choices takes off a bonus the new background does not raise), the same
# way the page does with app/javascript/choice_effects: the effects of the option picked before are taken back, those
# of the new one applied (decision: replaced). Needed on the server since the creation is in steps: the background,
# on its step, ticks skills of another step. A list whose option did not change applies nothing: what the player
# changed by hand stays
module CharacterSheets
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

        replace_effects(applied_sheet, field, field["effects"][previous_option.to_s].to_h,
                        field["effects"][picked_option.to_s].to_h)
      end
    end

    private

    def replace_effects(sheet, field, previous_effects, picked_effects)
      ChoiceEffects.all.each do |effect|
        effect.apply(sheet, previous_effects[effect.key], picked_effects[effect.key],
                     list_key: field["key"], fields: @fields)
      end
    end
  end
end
