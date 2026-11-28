# The texts of the panel « Rencontre » of the game room (EncounterBudget)
module EncountersHelper
  # « 4 personnages · niveaux 3, 3, 4 et 5 », or that no character is finished yet
  def encounter_party_text(levels)
    return t("game_rooms.panels.encounter.no_party") if levels.empty?

    t("game_rooms.panels.encounter.party", count: levels.size, levels: levels.to_sentence)
  end

  # « FP 1/4 · 50 XP »
  def encounter_creature_detail(creature)
    t("game_rooms.panels.encounter.creature_detail", rating: creature.rating,
                                                     xp: t("game_rooms.panels.encounter.xp",
                                                           count: number_with_delimiter(creature.xp)))
  end
end
