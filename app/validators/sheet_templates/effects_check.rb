module SheetTemplates
  # The effects of the options of the lists of the character sheet (ChoiceEffects): known effects, each one naming
  # fields of the type it declares (proficient: bonuses, ability_bonus_choices: abilities...), and its own value
  # checked by itself (a spellcasting given level by level, starting equipment options that can be read)
  class EffectsCheck < Check
    def call
      character_fields.select { |field| field["effects"] }.flat_map do |field|
        field["effects"].flat_map do |option, effects|
          effects_errors(effects.to_h, context("character_fields", field).merge(option: option))
        end
      end
    end

    private

    def effects_errors(effects, place)
      effects.flat_map do |effect_key, value|
        effect = ChoiceEffects.find(effect_key)
        next [[:unknown_effect, place.merge(effect: effect_key)]] unless effect

        target_errors(effect, value, place) + effect.value_errors(value, item_groups: item_groups)
                                                    .map { |error_type, options| [error_type, place.merge(options)] }
      end
    end

    # A field of the type the effect declares, or any field of the sheet when it declares none (set)
    def target_errors(effect, value, place)
      wrong_keys = effect.target_keys(value) - candidate_keys(effect.target_type)
      wrong_keys.map do |key|
        next [:unknown_effect_target, place.merge(effect: effect.key, target: key)] unless effect.target_type

        [:wrong_effect_target, place.merge(effect: effect.key, target: key, expected: type_name(effect.target_type))]
      end
    end

    def candidate_keys(type)
      type ? keys_of_type(character_fields, type) : character_fields.pluck("key")
    end

    def item_groups
      @item_groups ||= fields_of("item_fields").find { |field| field["key"] == "group" }&.dig("options").to_a
    end
  end
end
