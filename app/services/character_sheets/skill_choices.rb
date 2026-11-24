# The skills a character picks (effect skill_choices of an option: the class offers count skills from a list), read
# on its sheet. The same reading as character_sheet_controller.js#showSkillChoices: a skill another option picked
# already gives (proficient: the background ticks its own) is neither offered nor counted. Only the skills some option
# of the template may offer are concerned (the saving throws, ticked by the class, are not)
module CharacterSheets
  class SkillChoices
    def initialize(fields:, sheet:)
      @choice_fields = fields.select { |field| field["effects"].present? }
      @sheet = sheet.to_h
    end

    # Whether an option picked offers skills to pick: nothing to check before the class is chosen
    def offered?
      offers.any?
    end

    # How many skills to pick, all the options picked together
    def allowed_count
      offers.sum { |effects| effects.dig("skill_choices", "count").to_i }
    end

    # The keys of the skills the player may pick, without those already given
    def offered_keys
      offers.flat_map { |effects| effects.dig("skill_choices", "from").to_a }.uniq - granted_keys
    end

    # The keys of the skills given by the options picked
    def granted_keys
      picked_effects.flat_map { |effects| effects["proficient"].to_a }.uniq
    end

    # Every skill some option of the template may offer, ticked on the sheet
    def ticked_keys
      skill_keys.select { |key| @sheet[key] == true }
    end

    # The skills the player ticked among those offered
    def chosen_keys
      ticked_keys & offered_keys
    end

    # The skills ticked that no option picked offers nor gives
    def not_offered_keys
      ticked_keys - offered_keys - granted_keys
    end

    def too_many?
      chosen_keys.size > allowed_count
    end

    # Every skill some option of the template may offer: the fields the limit looks at
    def skill_keys
      @choice_fields.flat_map do |field|
        field["effects"].values.flat_map { |effects| effects.to_h.dig("skill_choices", "from").to_a }
      end.uniq
    end

    private

    def offers
      picked_effects.select { |effects| effects["skill_choices"] }
    end

    def picked_effects
      @choice_fields.filter_map { |field| field["effects"][@sheet[field["key"]]] }
    end
  end
end
