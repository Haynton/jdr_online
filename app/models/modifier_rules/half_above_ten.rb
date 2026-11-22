module ModifierRules
  # (score - 10) / 2, rounded down: 14 gives +2, 9 gives -1 (the rule of the heroic fantasy)
  class HalfAboveTen
    KEY = "half_above_ten".freeze

    def key
      KEY
    end

    def modifier(score)
      (score - 10).div(2)
    end
  end
end
