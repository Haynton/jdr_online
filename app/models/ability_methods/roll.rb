module AbilityMethods
  # Dice rolled for each ability, the best ones kept (4d6, keeping the 3 best). The server rolls
  # (CharacterSheets::AbilityScoreRoller), the player places the results or types their own: an aid, never a check
  # (decision: a game played with real dice)
  class Roll < Base
    KEY = "roll".freeze
    GUIDE_PARTIAL = "character_sheets/ability_methods/roll".freeze
    OWN_PARAMETERS = %w[dice sides keep_highest].freeze
    REQUIRED_PARAMETERS = %w[dice sides].freeze

    def places_results?
      true
    end

    def settings_errors(method, **)
      return [] if valid_dice?(method)

      [[:invalid_ability_method_dice, { method: method["label"] }]]
    end

    private

    # Whole dice and sides, and no more dice kept than rolled
    def valid_dice?(method)
      dice = method["dice"]
      kept = method.fetch("keep_highest", dice)
      [dice, method["sides"], kept].all? { |number| positive_integer?(number) } && kept <= dice
    end
  end
end
