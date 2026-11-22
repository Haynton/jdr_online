# The bonus of the background on the abilities step (decision, rules of 2024): in the guide beside the tiles, each
# ability its option raises gets +0, +1 or +2, and the guide says what is left to place (ability_bonus_controller.js).
# The bonus is kept apart from the score typed (CharacterSheets::Calculator adds them)
module CharacterSheets
  module CharacterSheets::AbilityBonusesHelper
    BONUS_CHOICES = [0, 1, 2].freeze
    # The columns of the bonus block, the same for its headings and its lines: the name (112 px, 96 px on a phone),
    # the choices (148 px: three of 44 px, two gaps and the padding of 4 px) and the final score (56 px). Fixed, so that
    # nothing stretches; narrower on a phone, where 348 px ran 5 px past the content
    BONUS_COLUMNS = "grid grid-cols-[6rem_9.25rem_3.5rem] gap-x-3 sm:grid-cols-[7rem_9.25rem_3.5rem] sm:gap-x-4".freeze
    COUNT_PLACEHOLDER = "%{count}".freeze # rubocop:disable Style/FormatStringToken
    BONUS_PLACEHOLDER = "%{bonus}".freeze # rubocop:disable Style/FormatStringToken

    def ability_bonus_field(fields)
      fields.find { |field| field["type"] == "ability_bonuses" }
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

    # What the controller writes in the panel: what is left to place, or that it is done, or too much. The text for
    # several points keeps its placeholder for the controller (COUNT_PLACEHOLDER)
    def ability_bonus_data
      scope = "game_tables.characters.new"
      { controller: "ability-bonus",
        ability_bonus_left_one_value: t("#{scope}.bonus_left_one"),
        ability_bonus_left_other_value: t("#{scope}.bonus_left_other", count: COUNT_PLACEHOLDER),
        ability_bonus_done_value: t("#{scope}.bonus_done"),
        ability_bonus_too_many_value: t("#{scope}.bonus_too_many") }
    end

    # The same text as the controller writes, for the page as it opens (and without JavaScript)
    def ability_bonus_status(character, bonus_field)
      scope = "game_tables.characters.new"
      return t("#{scope}.bonus_too_many") if ability_bonus_too_many?(character, bonus_field)

      bonuses = character.sheet[bonus_field["key"]].to_h.values.map(&:to_i)
      return t("#{scope}.bonus_done") if bonuses.sum == 3

      left = 3 - bonuses.sum
      left == 1 ? t("#{scope}.bonus_left_one") : t("#{scope}.bonus_left_other", count: left)
    end

    # +2 twice, or more than 3 in all: the status is an error, in red (ability_bonus_status_classes)
    def ability_bonus_too_many?(character, bonus_field)
      bonuses = character.sheet[bonus_field["key"]].to_h.values.map(&:to_i)
      bonuses.sum > 3 || bonuses.count(2) > 1
    end

    # The controllers of the abilities section: the roll of the dice when the template has one, and the bonus
    def abilities_section_data(game_table)
      roll_data = ability_roll_data(game_table)
      bonus_data = ability_bonus_data
      roll_data.merge(bonus_data, controller: [roll_data[:controller], bonus_data[:controller]].compact.join(" "))
    end

    private

    def picked_list_effects(character, bonus_field)
      list = character.sheet_fields.find { |field| field["key"] == bonus_field["from"] }
      list&.dig("effects", character.sheet[bonus_field["from"]].to_s).to_h
    end
  end
end
