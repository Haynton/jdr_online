# The guide of the scores on the abilities step: the way the character gets them (Character#ability_method_in_use,
# AbilityMethods). The roll and the standard array give results to place from a list in each tile
# (ability_roll_controller.js: the server rolls the dice, the array is given as it is); the point buy counts the
# points spent (point_buy_controller.js)
module CharacterSheets
  module CharacterSheets::AbilityRollsHelper
    # An option of the choice of the way, as the switch of the starting equipment, but sharing the width of the guide
    # (352 px) with the others, its text a little smaller: three ways hold on one line
    ABILITY_METHOD_OPTION_CLASSES = %w[
      inline-flex min-h-8 min-w-0 flex-auto cursor-pointer items-center justify-center rounded-md px-1.5 py-1
      text-center text-[13px] leading-tight text-ink transition-colors hover:bg-surface/60 has-checked:bg-surface
      has-checked:font-semibold has-checked:shadow-sm has-focus-visible:outline-2 has-focus-visible:outline-offset-2
      has-focus-visible:outline-focus-ring
    ].join(" ").freeze

    # Filled by point_buy_controller.js as the player types
    SPENT_PLACEHOLDER = "%{spent}".freeze # rubocop:disable Style/FormatStringToken
    POINTS_PLACEHOLDER = "%{points}".freeze # rubocop:disable Style/FormatStringToken

    def ability_method_option_classes
      ABILITY_METHOD_OPTION_CLASSES
    end

    def ability_method_type(character)
      character.ability_method_in_use&.dig("type")
    end

    def ability_results_placed?(character)
      type = ability_method_type(character)
      type.present? && AbilityMethods.find(type).places_results?
    end

    # What the controllers of the guide need: where the server rolls and the texts it writes, or the values of the
    # array; the costs and the points of a point buy
    def ability_method_data(character)
      method = character.ability_method_in_use
      case method&.dig("type")
      when AbilityMethods::Roll::KEY then ability_roll_data(character)
      when AbilityMethods::StandardArray::KEY then standard_array_data(method)
      when AbilityMethods::PointBuy::KEY then point_buy_data(method)
      else {}
      end
    end

    # "12 points spent out of 27", worked out on the scores saved (point_buy_controller.js counts them while typing)
    def point_buy_status(character, method)
      t("game_tables.characters.new.points_spent", spent: points_spent(character, method), points: method["points"])
    end

    def points_spent(character, method)
      costs = AbilityMethods::PointBuy.costs(method)
      character.game_table.ability_fields.sum { |field| costs[character.sheet[field["key"]]].to_i }
    end

    # The score of an ability: the live calculation reads it to work out its modifier, and shows the bonus of the
    # background in it. autocomplete off: a browser that restored the score shown (bonus included) on coming back to
    # the page would get the bonus added twice. With a point buy, the score typed stays within its costs (8 to 15): its
    # bounds, the highest kept apart for the bonus shown in it (typed_max)
    def sheet_ability_input(character, field, **options)
      bounds = ability_score_bounds(character)
      data = { character_sheet_target: "score", ability: field["key"], modifier_rule: field["modifier"],
               typed_max: bounds&.last }
      readonly = options.key?(:readonly) ? options.delete(:readonly) : placed_only?(character)
      sheet_stepper_input(character, field, autocomplete: "off", data: data.compact, bounds: bounds,
                                            readonly: readonly, **options)
    end

    # The table turns the scores typed by hand off with a roll: a score is only placed from the results
    def placed_only?(character)
      ability_method_type(character) == AbilityMethods::Roll::KEY && !character.game_table.ability_scores_typed
    end

    # The bounds of a score typed with a point buy (8 to 15), nil for the other ways
    def ability_score_bounds(character)
      method = character.ability_method_in_use
      return unless method&.dig("type") == AbilityMethods::PointBuy::KEY

      AbilityMethods::PointBuy.costs(method).keys.minmax
    end

    private

    # The roll kept shows again (ability_rolls), and « Relancer » goes once there is no roll left (one roll again, when
    # the table allows it)
    def ability_roll_data(character)
      game_table = character.game_table
      { controller: "ability-roll", ability_roll_url_value: game_table_ability_roll_path(game_table),
        ability_roll_reroll_label_value: t("game_tables.characters.new.reroll"),
        ability_roll_placeholder_value: t("game_tables.characters.new.place_result"),
        ability_roll_rolled_value: Array(character.ability_rolls).to_json,
        ability_roll_rerolls_value: character.may_roll_abilities? }
    end

    def standard_array_data(method)
      { controller: "ability-roll", ability_roll_preset_value: method["values"].to_json,
        ability_roll_placeholder_value: t("game_tables.characters.new.place_value") }
    end

    def point_buy_data(method)
      { controller: "point-buy", action: "input->point-buy#count change->point-buy#count",
        point_buy_costs_value: AbilityMethods::PointBuy.costs(method).to_json,
        point_buy_points_value: method["points"],
        point_buy_template_value: t("game_tables.characters.new.points_spent", spent: SPENT_PLACEHOLDER,
                                                                               points: POINTS_PLACEHOLDER) }
    end
  end
end
