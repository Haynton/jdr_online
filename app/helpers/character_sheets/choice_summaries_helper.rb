# The summary of the options picked in the lists that have descriptions (class, species, background), beside them on
# the first step of the creation (character_sheets/sections/_described_choices): not everyone knows what a druid or an
# acolyte is. Each option: its description, written in the template, then what it brings, read from its effects
module CharacterSheets
  module CharacterSheets::ChoiceSummariesHelper
    # The lists of the section whose options have a description
    def described_choice_fields(fields)
      fields.select { |field| field["descriptions"] }
    end

    # The option picked shows from the start (without JavaScript too); described_choices_controller.js follows the list
    def choice_option_hidden?(character, field, option)
      character.sheet[field["key"]] != option
    end

    def choice_picked?(character, field)
      field["options"].include?(character.sheet[field["key"]])
    end

    # [label, text] for each effect of an option that a player can read, in the order of the registry (ChoiceEffects):
    # each effect says what it brings (the others are kept for the next steps)
    def choice_option_facts(field, option, all_fields)
      effects = field.dig("effects", option).to_h
      fields_by_key = all_fields.index_by { |candidate| candidate["key"] }
      ChoiceEffects.all.flat_map { |effect| effect.facts(effects[effect.key], fields_by_key) }
    end
  end
end
