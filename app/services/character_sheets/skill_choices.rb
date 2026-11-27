# The skills a character picks (effect skill_choices of an option: the class offers count skills from a list), read
# on its sheet. The same reading as character_sheet_controller.js#showSkillChoices: a skill another option picked
# already gives (proficient: the background ticks its own) is neither offered nor counted. Only the skills some option
# of the template may offer are concerned (the saving throws, ticked by the class, are not)
module CharacterSheets
  class SkillChoices
    # granted: skills given beside the options (those of a feat: Skilled)
    def initialize(fields:, sheet:, granted: [])
      @choice_fields = fields.select { |field| field["effects"].present? }
      @sheet = sheet.to_h
      @granted = granted
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
      (picked_effects.flat_map { |effects| effects["proficient"].to_a } + @granted).uniq
    end

    # Which option picked gives each skill it gives ({ "intimidation" => "Soldat" }): the page says it on its line
    def given_by
      @choice_fields.each_with_object({}) do |field, sources|
        option = @sheet[field["key"]]
        field["effects"][option].to_h["proficient"].to_a.each { |key| sources[key] ||= option }
      end
    end

    # Every skill some option of the template may offer, ticked on the sheet
    def ticked_keys
      skill_keys.select { |key| FieldTypes::Bonus.proficient?(@sheet[key]) }
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

    # Whether the skills chosen share out between the options picked, each taking its own in its list (a human ranger:
    # 3 of the list of the ranger, 1 of every skill; two skills outside the list of the ranger do not fit)
    def fit_offers?
      slots = offers.flat_map do |effects|
        Array.new(effects.dig("skill_choices", "count").to_i, effects.dig("skill_choices", "from").to_a)
      end
      holders = {}
      chosen_keys.all? { |key| place(key, slots, holders, []) }
    end

    # The options picked that offer skills, with how many each: "Rôdeur : 3, Humain : 1"
    def offers_text
      @choice_fields.filter_map do |field|
        count = field["effects"][@sheet[field["key"]]].to_h.dig("skill_choices", "count")
        "#{@sheet[field['key']]} : #{count}" if count
      end.join(", ")
    end

    # Every field some option of the template may give without picking (the saving throws of a class)
    def givable_keys
      @choice_fields.flat_map { |field| field["effects"].values.flat_map { |effects| effects.to_h["proficient"].to_a } }
                    .uniq
    end

    # Every skill some option of the template may offer: the fields the limit looks at
    def skill_keys
      @choice_fields.flat_map do |field|
        field["effects"].values.flat_map { |effects| effects.to_h.dig("skill_choices", "from").to_a }
      end.uniq
    end

    private

    # Puts a skill in a slot of its list, moving the skill already there to another slot when it may go elsewhere
    def place(key, slots, holders, visited)
      slots.each_index.any? do |index|
        next false if visited.include?(index) || slots[index].exclude?(key)

        visited << index
        holder = holders[index]
        next false unless holder.nil? || place(holder, slots, holders, visited)

        holders[index] = key
      end
    end

    def offers
      picked_effects.select { |effects| effects["skill_choices"] }
    end

    def picked_effects
      @choice_fields.filter_map { |field| field["effects"][@sheet[field["key"]]] }
    end
  end
end
