module ComputedRules
  # One die per level typed in level_from, its sides the hit_die of the class chosen in class_from: "3d8" for a
  # cleric of level 3. Nothing until a class of the list is chosen
  class HitDiceByClass < Base
    KEY = "hit_dice_by_class".freeze
    REQUIRED_PARAMETERS = %w[level_from class_from].freeze
    READS_HIT_DIE = true

    def value(field, reader)
      sides = reader.class_effects(field["class_from"])["hit_die"]
      "#{reader.typed_level(field['level_from'])}d#{sides}" if sides
    end
  end
end
