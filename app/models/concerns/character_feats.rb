# The feats of a player's character (decision of 27 November): the origin feat of its background and those it took
# (characters.feats, at a level gained: LevelUp; the origin feat of the human, at its creation), and the spells a feat
# gives to pick (Magic Initiate: for the origin feat of a background, at the step of the skills), read by
# CharacterSheets::Feats. Their points to the abilities and their effects reach the rules through the play state of
# the sheet (Character#computed_sheet_values)
module CharacterFeats
  extend ActiveSupport::Concern
  include CharacterFeatOrigins
  include CharacterLevelFeats

  def feat_list
    CharacterSheets::Feats.new(self)
  end

  BACKGROUND_SOURCE = "background".freeze
  SPECIES_SOURCE = "species".freeze

  included do
    attr_accessor :checks_feat_spells

    validates_with CharacterFeatSpellsValidator
  end

  def feat_spells
    CharacterSheets::FeatSpells.new(self)
  end

  # The origin feat of an option picked (the background) that gives spells to pick (Magic Initiate), with its fixed
  # list: { feat:, settings: } (the settings of the feat, its list narrowed to the one of the option), nil otherwise
  def origin_feat_spells
    return unless game_table.origin_feats

    origin = sheet_fields.filter_map { |field| field.dig("effects", sheet[field["key"]].to_s, "origin_feat") }.first
    feat = origin && feat_list.find(origin["key"])
    settings = feat&.effects&.dig("spell_picks")
    return unless settings && origin["spell_list"]

    { feat: feat, settings: settings.merge("lists" => [origin["spell_list"]]) }
  end

  # What its origin feat picked (the entry of the background in feats), {} before
  def origin_feat_picks
    Array(feats).find { |entry| entry["source"] == BACKGROUND_SOURCE }.to_h
  end

  # The spells picked for the origin feat of its background (the step of the skills), in the list it fixes
  def choose_origin_feat_spells(picks)
    given = origin_feat_spells
    others = Array(feats).reject { |entry| entry["source"] == BACKGROUND_SOURCE }
    self.feats = given ? others + [origin_entry(given, picks.to_h)] : others
    sync_feat_spells
  end

  # A background changed drops what its old origin feat picked
  def keep_offered_origin_feat_spells
    given = origin_feat_spells
    picks = origin_feat_picks
    return if picks.empty? || (given && given[:settings]["lists"].include?(picks["spell_list"]))

    choose_origin_feat_spells({})
  end

  # The feat an option picked lets it pick (the human: an origin feat), { "categories" }, nil otherwise
  def feat_choice_settings
    return unless game_table.origin_feats

    sheet_fields.filter_map { |field| field.dig("effects", sheet[field["key"]].to_s, ChoiceEffects::FeatChoice::KEY) }
                .first
  end

  def species_feat_offers
    settings = feat_choice_settings
    return [] unless settings

    feat_list.offered(level: current_level, categories: settings["categories"], ignoring: SPECIES_SOURCE)
  end

  def species_feat_entry
    Array(feats).find { |entry| entry["source"] == SPECIES_SOURCE }.to_h
  end

  # The feat picked through an option (the human), with what it asks: the skills of Skilled (ticked on the sheet, those
  # of the feat picked before unticked), the spells of Magic Initiate
  def choose_species_feat(params)
    params = params.to_h.stringify_keys
    untick_skills(species_feat_entry["skills"])
    others = Array(feats).reject { |entry| entry["source"] == SPECIES_SOURCE }
    entry = species_entry(params)
    self.feats = entry ? others + [entry] : others
    tick_skills(entry.to_h["skills"])
    sync_feat_spells
  end

  # The skills its feats give (Skilled) stay ticked when another class unticks those picked in its old list
  def keep_feat_skills_ticked
    tick_skills(feat_list.skill_keys)
  end

  # An option changed (the species) drops the feat it no longer lets pick
  def keep_offered_species_feat
    choose_species_feat({}) if species_feat_entry.any? && feat_choice_settings.nil?
  end

  # Its spells: those it picked for its class, then a copy of those of its feats
  def sync_feat_spells
    self.spells = spells.to_a.reject { |spell| spell[CharacterSheets::FeatSpells::MARK] } + feat_spells.copies
  end

  # What its feats give the rules (CharacterSheets::PlayState): their points to the abilities, their effects
  def feat_play_values
    return {} unless pc?

    feats = feat_list
    { ability_increases: feats.ability_increases.to_h, feat_effects: feats.rule_effects }
  end

  # The effects of the fighting styles its feats give, with those of the style picked of its class
  def fighting_style_effects_with_feats(class_style_effects)
    return class_style_effects unless pc?

    class_style_effects.merge(feat_list.rule_effects.except("initiative_proficiency"))
  end

  private

  # The card picked names the feat and its list (CharacterSheets::FeatCards: « magic-initiate~Druide »)
  def species_entry(params)
    key, list = CharacterSheets::FeatCards.split(params["key"])
    feat = feat_choice_settings && feat_list.find(key)
    return unless feat

    entry = { "key" => feat.key, "source" => SPECIES_SOURCE }
    entry["skills"] = Array(params["skills"]).compact_blank.uniq if feat.effects["skill_picks"]
    return entry unless feat.effects["spell_picks"]

    entry.merge(CharacterSheets::FeatSpells.picks_from(params["feat_spells"], list: list))
  end

  def tick_skills(keys)
    self.sheet = sheet.merge(Array(keys).index_with(true)) if Array(keys).any?
  end

  def untick_skills(keys)
    self.sheet = sheet.except(*Array(keys)) if Array(keys).any?
  end

  def origin_entry(given, picks)
    { "key" => given[:feat].key, "source" => BACKGROUND_SOURCE, "spell_list" => given[:settings]["lists"].first,
      "spell_ability" => picks["spell_ability"].presence, "cantrips" => Array(picks["cantrips"]).compact_blank,
      "spell" => picks["spell"].presence }.compact
  end
end
