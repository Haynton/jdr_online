# The window of the level gained in the game room (LevelUp, game_tables/level_ups/new)
module LevelUpsHelper
  # A choice drawn like the theme selector (field background, the one picked a surface pill in bold), on a real radio
  # button hidden under its label
  CHOICE_CLASSES = %w[
    inline-flex h-8 min-w-11 cursor-pointer items-center justify-center rounded-md px-3 text-sm text-ink
    transition-colors hover:bg-surface/60 has-checked:bg-surface has-checked:font-semibold has-checked:shadow-sm
    has-focus-visible:outline-2 has-focus-visible:outline-offset-2 has-focus-visible:outline-focus-ring
  ].join(" ").freeze
  SECTION_TITLE_CLASSES = "text-xs font-semibold tracking-wider text-brass uppercase".freeze

  # The features the options picked give at the new level exactly (CharacterSheets::Features), said before the choices
  def level_up_features(level_up)
    features = CharacterSheets::Features.new(level_up.character)
    level_up.character.sheet_fields.flat_map do |field|
      option = level_up.character.sheet[field["key"]]
      next [] unless field["effects"].is_a?(Hash) && field.dig("effects", option.to_s)

      features.features_of(field, option).select { |feature| feature.level == level_up.level }
    end
  end

  # The points an ability may gain: +0 to the most allowed on one ability
  def level_up_increase_choices(level_up)
    (0..level_up.improvement["max_per_ability"]).to_a
  end

  # The new spells and weapon masteries are picked afterwards, in their own windows: said when the character has some
  def level_up_picks_later?(character)
    character.spells.present? || character.weapon_mastery_choices.offered?
  end
end
