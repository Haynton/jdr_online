module SheetTemplates
  # The feats of the template (character_fields.feats), when it declares them: each a key, a category among those it
  # names (feat_categories: their labels, in the words of the game), what it needs (min_level, ability_minimum: one of
  # these abilities at that score, needs_effect: an effect the options picked give, NEEDS), whether it may be taken
  # again (repeatable) and its effects from a closed list (EFFECTS); its name and summary are in the catalog of
  # features (Catalogs::TableCatalog). A fighting style it gives is one of character_fields.fighting_styles
  class FeatsCheck < Check
    PARAMETERS = %w[key category min_level ability_minimum needs_effect repeatable effects].freeze
    # What a feat may do: raise abilities, give skills to pick, give a fighting style, add the proficiency bonus to the
    # initiative, give spells to pick from lists
    EFFECTS = %w[ability_increase skill_picks fighting_style initiative_proficiency spell_picks].freeze
    # The effects of the options picked a feat may need: a class with a fighting style, a class that casts spells
    NEEDS = %w[fighting_style spellcasting].freeze

    def call
      feats = character_settings["feats"]
      return [] if feats.nil?
      return [[:invalid_feats, {}]] unless feats.is_a?(Array) && character_settings["feat_categories"].is_a?(Hash)

      feats.flat_map { |feat| feat_errors(feat) }
    end

    private

    def character_settings
      @sheet_template.character_fields.to_h
    end

    def feat_errors(feat)
      return [[:invalid_feats, {}]] unless feat.is_a?(Hash)
      return [] if valid_feat?(feat)

      [[:invalid_feat, { feat: feat["key"].to_s }]]
    end

    def valid_feat?(feat)
      (feat.keys - PARAMETERS).empty? && feat["key"].to_s.match?(ClassChoicesCheck::OPTION_KEY_FORMAT) &&
        character_settings["feat_categories"].key?(feat["category"]) &&
        (feat["min_level"].nil? || feat["min_level"].in?(1..20)) &&
        (feat["needs_effect"].nil? || NEEDS.include?(feat["needs_effect"])) && valid_effects?(feat["effects"].to_h)
    end

    def valid_effects?(effects)
      styles = Array(character_settings["fighting_styles"]).filter_map { |style| style["key"] if style.is_a?(Hash) }
      (effects.keys - EFFECTS).empty? && (effects["fighting_style"].nil? || styles.include?(effects["fighting_style"]))
    end
  end
end
