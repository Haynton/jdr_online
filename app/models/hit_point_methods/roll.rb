module HitPointMethods
  # At each level after the first, a roll of the hit die, made once by the server on the summary of the character
  # (decision: no second roll, the rule would lose its sense), kept with the die it was rolled with
  class Roll < Base
    KEY = "roll".freeze
    # Given to the rules instead of the rolls while a roll the table imposes is still to make: the hit points are not
    # known yet (ComputedRules::HitPointsByLevel shows nothing)
    NOT_ROLLED = :not_rolled

    def rolls_dice?
      true
    end
  end
end
