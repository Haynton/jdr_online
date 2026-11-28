# The step « Dons des niveaux » (game_tables/character_steps/_level_feats): the feats of the levels a character starts
# above, one level per tab, the feats as tiles with their emblem (the look of the classes), the points of a feat that
# raises the abilities as tokens placed on the six cards of the abilities step (ability_tokens_controller.js). The form
# sends what the window of a level gained sends (CreationFeat: feat_key, ability_increases, skills, spells)
module CharacterSheets
  module LevelFeatsHelper
    SCOPE = "game_tables.character_steps.level_feats".freeze
    # The emblem of a feat the template names none for
    DEFAULT_FEAT_ICON = "scroll_text".freeze

    # The feats that come latest first (the epic boons from level 19, then the feats of the levels, then the origin
    # feats), in the order of the template within a level: those meant for this level before those of the creation
    def level_feat_cards_in_order(level_feat)
      level_feat.feat_cards.each_with_index.sort_by { |card, index| [-card.feat.min_level, index] }.map(&:first)
    end

    # The tab shown first: the first level with an error, else the first one
    def level_feat_selected_index(level_feats)
      level_feats.index { |level_feat| level_feat.errors.any? } || 0
    end

    # « Amélioration de caractéristique · SAG +2 », under the level of its tab
    def level_feat_summary(level_feat)
      points = level_feat.ability_increases.to_h.select { |_key, value| value.to_i.positive? }.map do |key, value|
        field = level_feat.ability_fields.find { |candidate| candidate["key"] == key }
        "#{field&.dig('abbreviation') || key} +#{value}"
      end
      [level_feat.feat&.name, *points].compact.join(" · ")
    end

    # Whether its feat asks nothing more, or its points are all placed
    def level_feat_complete?(level_feat)
      settings = level_feat.increase_settings
      level_feat.errors.none? &&
        (settings.nil? || level_feat.ability_increases.to_h.values.sum(&:to_i) == settings["points"].to_i)
    end

    # What a tile tells the cards: how many points the feat gives, at most on one ability, the highest score, the
    # abilities it may raise (none: no cards)
    def level_feat_tile_data(level_feat, card)
      settings = level_feat.increase_settings(card.feat)
      return { points: 0 } unless settings

      { points: settings["points"].to_i, per_ability: settings["max_per_ability"].to_i,
        maximum: settings["maximum"].to_i, abilities: level_feat.increase_fields(card.feat).pluck("key").to_json }
    end

    def level_feat_icon(feat)
      OptionIcons.partial(feat.icon) || OptionIcons.partial(DEFAULT_FEAT_ICON)
    end

    # The score of an ability before this level (the scores of the character without the feats of this level and the
    # later ones), 10 when it has none yet
    def level_feat_score_before(level_feat, field)
      level_feat.score_of(field) || 10
    end

    def level_feat_modifier(field, score)
      format_bonus(ModifierRules.modifier(score, field["modifier"]))
    end

    # The texts the controller writes, its number to fill (__POINTS__)
    def level_feat_texts
      { placed: t("#{SCOPE}.placed", points: "__POINTS__"), gain: t("#{SCOPE}.gain") }.to_json
    end
  end
end
