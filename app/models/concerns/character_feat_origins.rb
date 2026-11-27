# Where a feat of a player's character comes from, as the page names it (decision of 27 November: each block of feat
# spells says its source, and a spell known already says where it is from): the option that gives it (the background,
# the species) or the level it was taken at. Part of CharacterFeats
module CharacterFeatOrigins
  extend ActiveSupport::Concern

  # Where a feat taken comes from, as the page names it: « Initié à la magie (Acolyte) », « … (niveau 4) »
  def feat_entry_label(entry)
    name = feat_list.find(entry["key"])&.name || entry["key"].to_s.humanize
    I18n.t("game_tables.character_steps.feat_spells.known.feat", feat: name, origin: feat_origin(entry))
  end

  # The option that gives a feat of that source (the background, the species), the level it was taken at otherwise
  def feat_origin(entry)
    effect = { CharacterFeats::BACKGROUND_SOURCE => ChoiceEffects::OriginFeat::KEY,
               CharacterFeats::SPECIES_SOURCE => ChoiceEffects::FeatChoice::KEY }
    return picked_option_with(effect[entry["source"]]) if effect[entry["source"]]

    I18n.t("game_tables.character_steps.feat_spells.known.level", level: entry["level"])
  end

  # The origin feat its background gives (Alert for the criminal), nil when the table plays no origin feats
  def background_feat
    return unless game_table.origin_feats

    key_path = [ChoiceEffects::OriginFeat::KEY, "key"]
    key = sheet_fields.filter_map { |field| field.dig("effects", sheet[field["key"]].to_s, *key_path) }.first
    key && feat_list.find(key)
  end

  # The origin feats of its creation, to show them: [feat, entry (what was picked for it), its source]
  def origin_feats_taken
    background = background_feat && [background_feat, origin_feat_picks, CharacterFeats::BACKGROUND_SOURCE]
    species = species_feat_entry.presence
    species &&= [feat_list.find(species["key"]), species, CharacterFeats::SPECIES_SOURCE]
    [background, species].compact.select(&:first)
  end

  # Which feat gives each skill its feats give ({ "arcana" => "Doué (Humain)" })
  def feat_skill_sources
    feat_list.taken_entries.each_with_object({}) do |entry, sources|
      Array(entry["skills"]).each { |key| sources[key] ||= feat_entry_label(entry) }
    end
  end

  private

  def picked_option_with(effect_key)
    field = sheet_fields.find { |candidate| candidate.dig("effects", sheet[candidate["key"]].to_s, effect_key) }
    field && sheet[field["key"]]
  end
end
