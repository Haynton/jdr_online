# The feats of a character and those it may take (decision of 27 November, SRD 5.2.1): the template declares each feat
# once (character_fields.feats: its category, what it needs, its effects), its name and summary are in the catalog of
# features of the table. A character has the origin feat of its background (the effect origin_feat of an option
# picked) and the feats it took (characters.feats: at a level that improves its abilities, at an epic level, the origin
# feat of the human). No rule of a game is written here
module CharacterSheets
  class Feats
    Feat = Data.define(:key, :name, :description, :category, :min_level, :ability_minimum, :needs_effect, :repeatable,
                       :effects)
    # The categories a feat may come from at a level that improves the abilities; and at an epic level, the epic boons
    COMMON_CATEGORIES = %w[origin general fighting_style].freeze
    EPIC_CATEGORY = "epic_boon".freeze
    ORIGIN_CATEGORY = "origin".freeze

    def initialize(character)
      @character = character
      @game_table = character.game_table
    end

    def find(key)
      declared.find { |feat| feat.key == key }
    end

    def category_label(feat)
      @game_table.feat_categories[feat.category]
    end

    # The feats it may take at that level (epic: the epic boons too; categories: only those, an origin feat for the
    # human): their level reached, their needs met, not taken yet unless they may be taken again (ignoring: the feat
    # taken from that source, which is being picked again)
    def offered(level:, epic: false, categories: nil, ignoring: nil)
      allowed = categories || (COMMON_CATEGORIES + (epic ? [EPIC_CATEGORY] : []))
      taken = origin_feat_keys + taken_entries.reject { |entry| ignoring && entry["source"] == ignoring }.pluck("key")
      declared.select do |feat|
        allowed.include?(feat.category) && available?(feat, level, taken) && lists_left?(feat, ignoring)
      end
    end

    # The keys of every feat it has: the origin feat of its background, then those it took
    def taken_keys
      origin_feat_keys + taken_entries.pluck("key")
    end

    def taken_entries
      Array(@character.feats)
    end

    # The skills its feats gave (Skilled): they count in none of the skills to pick of its class
    def skill_keys
      taken_entries.flat_map { |entry| Array(entry["skills"]) }.uniq
    end

    # The points its feats add to the abilities, by ability (kept apart from the score typed)
    def ability_increases
      taken_entries.each_with_object(Hash.new(0)) do |entry, increases|
        entry["abilities"].to_h.each { |ability, points| increases[ability] += points.to_i }
      end
    end

    # The effects of its feats the rules read: the proficiency to the initiative, the effects of the fighting styles
    # they give ({ "initiative_proficiency" => true, "ranged_attack_bonus" => 2 })
    def rule_effects
      taken_keys.filter_map { |key| find(key) }.each_with_object({}) do |feat, effects|
        effects["initiative_proficiency"] = true if feat.effects["initiative_proficiency"]
        effects.merge!(style_effects(feat.effects["fighting_style"]))
      end
    end

    private

    def declared
      @declared ||= Array(@game_table.feats).map { |feat| feat_of(feat) }
    end

    def feat_of(feat)
      entry = catalog[feat["key"]]
      Feat.new(key: feat["key"], name: entry&.name || feat["key"].humanize, description: entry&.description,
               category: feat["category"], min_level: feat["min_level"].to_i, ability_minimum: feat["ability_minimum"],
               needs_effect: feat["needs_effect"], repeatable: feat["repeatable"] == true,
               effects: feat["effects"].to_h)
    end

    def available?(feat, level, taken)
      feat.min_level <= level && ability_minimum_met?(feat.ability_minimum) && need_met?(feat.needs_effect) &&
        (feat.repeatable || taken.exclude?(feat.key))
    end

    # A feat that gives spells from a list has one its other feats did not take (Magic Initiate: another list each time)
    def lists_left?(feat, source)
      lists = feat.effects.dig("spell_picks", "lists")
      lists.nil? || (Array(lists) - @character.feat_spells.taken_lists(except: source)).any?
    end

    def ability_minimum_met?(minimum)
      return true unless minimum

      scores = @character.computed_sheet_values[:scores].to_h
      Array(minimum["abilities"]).any? { |ability| scores[ability].to_i >= minimum["score"].to_i }
    end

    def need_met?(effect_key)
      effect_key.nil? || picked_effects.any? { |effects| effects.key?(effect_key) }
    end

    # None when the table turns the origin feats off (GameTable#origin_feats)
    def origin_feat_keys
      return [] unless @game_table.origin_feats

      picked_effects.filter_map { |effects| effects.dig(ChoiceEffects::OriginFeat::KEY, "key") }
    end

    def picked_effects
      @picked_effects ||= @character.sheet_fields.filter_map do |field|
        field.dig("effects", @character.sheet[field["key"]].to_s) if field["effects"].is_a?(Hash)
      end
    end

    def style_effects(style_key)
      return {} unless style_key

      Array(@game_table.fighting_styles).find { |style| style["key"] == style_key }.to_h["effects"].to_h
    end

    def catalog
      @catalog ||= Catalogs::TableCatalog.new(@game_table).entries("feature").index_by(&:key)
    end
  end
end
