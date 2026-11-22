module ChoiceEffects
  # The sides of the hit dice of a class (8: d8), read by the rules hit_dice_by_class and hit_points_by_level
  class HitDie < Base
    KEY = "hit_die".freeze

    def facts(value, _fields_by_key)
      value ? [[fact_label(:hit_die), "d#{value}"]] : []
    end
  end
end
