module ComputedRules
  # At level 1, the highest roll of the hit die of the class (class_from) plus the modifier of based_on
  # (Constitution); then at each level typed in level_from, the average of the die (half plus one) plus that modifier.
  # A plain number, kept as a text ("8", not "+8"). Nothing until the class and the ability are known
  class HitPointsByLevel < Base
    KEY = "hit_points_by_level".freeze
    REQUIRED_PARAMETERS = %w[based_on level_from class_from].freeze
    READS_HIT_DIE = true

    def value(field, reader)
      sides = reader.class_effects(field["class_from"])["hit_die"]
      modifier = reader.modifier(field["based_on"])
      return unless sides && modifier

      levels_after_the_first = reader.typed_level(field["level_from"]) - 1
      (sides + modifier + (levels_after_the_first * ((sides / 2) + 1 + modifier))).to_s
    end
  end
end
