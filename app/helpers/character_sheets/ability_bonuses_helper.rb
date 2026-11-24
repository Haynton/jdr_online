# The bonus of the background on the abilities step (decision, rules of 2024): in the guide beside the tiles, each
# ability its option raises gets +0 up to the max_per_ability of the field (+2), the help of the field says the rule
# in the words of the game, and the guide says what is left to place of its total (ability_bonus_controller.js).
# The bonus is kept apart from the score typed (CharacterSheets::Calculator adds them)
module CharacterSheets
  module CharacterSheets::AbilityBonusesHelper
    # The columns of the bonus block, the same for its headings and its lines: the name (112 px, 96 px on a phone),
    # the choices (148 px: three of 44 px, two gaps and the padding of 4 px; a rule of more than +2 would need wider)
    # and the final score (56 px). Fixed, so that nothing stretches; narrower on a phone, where 348 px ran 5 px past
    # the content
    BONUS_COLUMNS = "grid grid-cols-[6rem_9.25rem_3.5rem] gap-x-3 sm:grid-cols-[7rem_9.25rem_3.5rem] sm:gap-x-4".freeze
    COUNT_PLACEHOLDER = "%{count}".freeze # rubocop:disable Style/FormatStringToken
    BONUS_PLACEHOLDER = "%{bonus}".freeze # rubocop:disable Style/FormatStringToken

    def ability_bonus_field(fields)
      fields.find { |field| field["type"] == "ability_bonuses" }
    end

    # +0 up to the max_per_ability of the field
    def ability_bonus_choices(bonus_field)
      FieldTypes.of(bonus_field).choices(bonus_field)
    end

    # The abilities the option picked raises (ability_bonus_choices of the background chosen at the first step)
    def raised_ability_keys(character, bonus_field)
      return [] unless bonus_field

      picked_list_effects(character, bonus_field)["ability_bonus_choices"].to_a
    end

    # The option picked in the list that gives the bonus (the background), nil before a choice
    def bonus_source_option(character, bonus_field)
      character.sheet[bonus_field["from"]].presence
    end

    def placed_ability_bonus(character, bonus_field, ability_key)
      character.sheet[bonus_field["key"]].to_h[ability_key].to_i
    end

    # "incl. +%{bonus} Soldier", written under the score of a tile by character_sheet_controller.js, which keeps
    # the placeholder for the bonus placed
    def ability_bonus_note_template(character, bonus_field)
      t("game_tables.characters.new.bonus_included", bonus: BONUS_PLACEHOLDER,
                                                     option: bonus_source_option(character, bonus_field))
    end

    def ability_bonus_input_name(bonus_field, ability_key)
      "character[sheet][#{bonus_field['key']}][#{ability_key}]"
    end

    # "Constitution, Intelligence et Sagesse": the abilities raised, by their labels
    def raised_ability_labels(character, bonus_field)
      labels = character.sheet_fields.to_h { |field| [field["key"], field["label"]] }
      raised_ability_keys(character, bonus_field).filter_map { |ability_key| labels[ability_key] }.to_sentence
    end

    # What the controller writes in the panel: what is left to place, or that it is done, or too much, by the rule of
    # the field. The text for several points keeps its placeholder for the controller (COUNT_PLACEHOLDER)
    def ability_bonus_data(bonus_field)
      scope = "game_tables.characters.new"
      { controller: "ability-bonus",
        ability_bonus_total_value: bonus_field["total"],
        ability_bonus_max_per_ability_value: bonus_field["max_per_ability"],
        ability_bonus_left_one_value: t("#{scope}.bonus_left_one"),
        ability_bonus_left_other_value: t("#{scope}.bonus_left_other", count: COUNT_PLACEHOLDER),
        ability_bonus_done_value: t("#{scope}.bonus_done"),
        ability_bonus_too_many_value: t("#{scope}.bonus_too_many") }
    end

    # The same text as the controller writes, for the page as it opens (and without JavaScript)
    def ability_bonus_status(character, bonus_field)
      scope = "game_tables.characters.new"
      return t("#{scope}.bonus_too_many") if ability_bonus_too_many?(character, bonus_field)

      left = bonus_field["total"].to_i - placed_bonuses(character, bonus_field).values.sum
      return t("#{scope}.bonus_done") if left.zero?

      left == 1 ? t("#{scope}.bonus_left_one") : t("#{scope}.bonus_left_other", count: left)
    end

    # More than the total, or more than max_per_ability on one ability: the status is an error, in red
    def ability_bonus_too_many?(character, bonus_field)
      FieldTypes.of(bonus_field).too_much?(placed_bonuses(character, bonus_field), bonus_field)
    end

    # The controllers of the abilities section: the way to get the scores (a roll, an array, a point buy), and the bonus
    # when the template has one
    def abilities_section_data(character, bonus_field)
      method_data = ability_method_data(character)
      bonus_data = bonus_field ? ability_bonus_data(bonus_field) : {}
      method_data.merge(bonus_data, controller: joined_data(method_data, bonus_data, :controller),
                                    action: joined_data(method_data, bonus_data, :action)).compact_blank
    end

    private

    def joined_data(*data, key)
      data.filter_map { |values| values[key] }.join(" ")
    end

    def placed_bonuses(character, bonus_field)
      character.sheet[bonus_field["key"]].to_h.transform_values(&:to_i)
    end

    def picked_list_effects(character, bonus_field)
      list = character.sheet_fields.find { |field| field["key"] == bonus_field["from"] }
      list&.dig("effects", character.sheet[bonus_field["from"]].to_s).to_h
    end
  end
end
