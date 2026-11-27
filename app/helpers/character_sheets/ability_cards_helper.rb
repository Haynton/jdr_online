# The abilities step as a game screen (decision, prototype "Création façon jeu"): a tray of tokens on top, the values
# to place (the standard array, or the results of the dice once rolled) and the bonus of the background, then six
# cards (character_sheets/fields/_ability_card). The player touches a token, then the card where it goes
# (ability_tokens_controller.js). The tokens only fill the fields the step always sends (the score typed of each
# ability, the bonus of each ability raised): the server checks them as before (AbilityMethods, FieldTypes::AbilityBonuses)
module CharacterSheets
  module AbilityCardsHelper
    # A token, a diamond with rounded corners: a value in ink, a bonus in gold; held, filled; used, faded
    TOKEN_CLASSES = %w[
      relative grid size-12 place-items-center text-base font-extrabold tabular-nums transition
      before:absolute before:inset-[7px] before:rotate-45 before:rounded-md before:border before:border-field-line
      before:bg-surface before:transition hover:-translate-y-0.5
      aria-pressed:-translate-y-0.5 aria-pressed:text-page aria-pressed:before:border-brass aria-pressed:before:bg-brass
      data-used:pointer-events-none data-used:opacity-30
    ].join(" ").freeze
    BONUS_TOKEN_CLASSES = "text-brass before:border-brass".freeze
    # A value still to roll: a "?" in a dashed diamond, not a button
    WAITING_TOKEN_CLASSES = "pointer-events-none text-muted before:border-dashed".freeze

    # The score in a round astride the foot of its card: placed or set by + and − (read only), or typed (a roll the
    # table lets the player type). "?" while empty. Read only, it lets a click through to its card (the card receives
    # the token), and shows its outline to the keyboard only
    SCORE_ROUND_CLASSES = %w[
      size-10 rounded-full border border-line bg-surface p-0 text-center text-base font-extrabold text-ink
      tabular-nums placeholder:font-medium placeholder:text-muted placeholder-shown:border-dashed
      placeholder-shown:border-field-line read-only:pointer-events-none focus-visible:outline-2
      focus-visible:outline-focus-ring
      group-data-ready/card:border-brass group-data-ready/card:ring-4 group-data-ready/card:ring-brass/20
      [appearance:textfield] [&::-webkit-inner-spin-button]:appearance-none
      [&::-webkit-outer-spin-button]:appearance-none
    ].join(" ").freeze

    # The tokens of the bonus: one "+1" per point the rule gives (total). Two on the same ability make +2, never more
    # than its max_per_ability (decision: a choice between "+2 and +1" and "+1 to each" was hard to understand; the
    # same rule, placed one point at a time)
    def ability_bonus_token_count(bonus_field)
      [bonus_field["total"].to_i, 0].max
    end

    # The score of a card: the stepper of the field, as a round; read only when it is only placed from the tokens
    def ability_card_score_input(character, field)
      sheet_ability_input(character, field, class: SCORE_ROUND_CLASSES, placeholder: "?",
                                            readonly: ability_score_placed_only?(character))
    end

    # The score is placed from the tokens (the standard array, a roll the table does not let the player type) or set by
    # the "+" and "−" of a point buy
    def ability_score_placed_only?(character)
      type = ability_method_type(character)
      [AbilityMethods::StandardArray::KEY, AbilityMethods::PointBuy::KEY].include?(type) || placed_only?(character)
    end

    def ability_score_stepped?(character)
      ability_method_type(character) == AbilityMethods::PointBuy::KEY
    end

    # The data of the section: the controllers of the way (roll, point buy), of the bonus, and of the tokens
    def ability_cards_section_data(character, bonus_field)
      section_data = abilities_section_data(character, bonus_field)
      tokens_data = ability_tokens_data(character, bonus_field)
      controllers = [section_data[:controller], tokens_data[:controller]].compact_blank.join(" ")
      section_data.merge(tokens_data, controller: controllers)
    end

    # The texts of the guide line under the tray (ability_tokens_controller.js): a point buy has no value to place, its
    # scores are set with + and −, within its costs and its points
    def ability_tokens_data(character, bonus_field)
      idle = ability_score_stepped?(character) ? "idle_typed" : "idle"
      { controller: "ability-tokens",
        ability_tokens_idle_value: t("character_sheets.ability_cards.#{idle}"),
        ability_tokens_hold_value_value: t("character_sheets.ability_cards.hold_value", value: "__VALUE__"),
        ability_tokens_max_per_ability_value: bonus_field&.dig("max_per_ability").to_i }
        .merge(bonus_tokens_data(character, bonus_field), point_buy_tokens_data(character))
    end

    def bonus_tokens_data(character, bonus_field)
      raised = bonus_field ? raised_ability_labels(character, bonus_field) : ""
      { ability_tokens_hold_bonus_value: t("character_sheets.ability_cards.hold_bonus",
                                           abilities: raised, most: bonus_field&.dig("max_per_ability").to_i) }
    end

    def point_buy_tokens_data(character)
      method = character.ability_method_in_use
      return {} unless ability_score_stepped?(character)

      { ability_tokens_costs_value: AbilityMethods::PointBuy.costs(method).to_json,
        ability_tokens_points_value: method["points"],
        ability_tokens_hold_raise_value: t("character_sheets.ability_cards.hold_raise"),
        ability_tokens_hold_lower_value: t("character_sheets.ability_cards.hold_lower") }
    end
  end
end
