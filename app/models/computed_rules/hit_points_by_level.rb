module ComputedRules
  # At level 1, the highest roll of the hit die of the class (class_from) plus the modifier of based_on
  # (Constitution); then at each level typed in level_from, the average of the die (half plus one) plus that modifier,
  # or, when the hit dice were rolled (HitPointMethods::Roll, reader.hit_point_rolls), each roll plus that modifier,
  # at least 1 a level (nil in the rolls: a level gained with the average, LevelUp); nothing while a roll the table
  # imposes is still to make. Plus, at each level, the points an
  # option adds (hit_points_per_level: the draconic resilience). A plain number, kept as a text ("8", not "+8").
  # Nothing until the class and the ability are known
  class HitPointsByLevel < Base
    KEY = "hit_points_by_level".freeze
    REQUIRED_PARAMETERS = %w[based_on level_from class_from].freeze
    READS_HIT_DIE = true

    def value(field, reader)
      effects = reader.class_effects(field["class_from"])
      sides = effects["hit_die"]
      modifier = reader.modifier(field["based_on"])
      return unless sides && modifier
      return if reader.hit_point_rolls == HitPointMethods::Roll::NOT_ROLLED

      points = sides + modifier + later_levels_points(field, reader, sides, modifier)
      (points + points_per_level(field, reader, effects)).to_s
    end

    private

    def points_per_level(field, reader, effects)
      effects["hit_points_per_level"].to_i * reader.typed_level(field["level_from"])
    end

    def later_levels_points(field, reader, sides, modifier)
      average = (sides / 2) + 1
      rolls = reader.hit_point_rolls
      return rolls.sum { |roll| [(roll || average) + modifier, 1].max } if rolls

      (reader.typed_level(field["level_from"]) - 1) * (average + modifier)
    end
  end
end
