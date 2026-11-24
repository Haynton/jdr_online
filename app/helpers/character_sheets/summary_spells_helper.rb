# The spells of a character on its summary sheet (character_sheets/summary/_spells): those always prepared first,
# then those chosen, by the groups the template declares
module CharacterSheets
  module CharacterSheets::SummarySpellsHelper
    SCOPE = CharacterSheets::SpellChoicesHelper::SCOPE

    # The spells chosen, for the summary sheet: [["Sorts mineurs", [...]], ["Sorts préparés de niveau 1", [...]]]
    # The spells always prepared come first, under their own title
    def summary_spell_groups(character)
      always_prepared, chosen = sorted_spells(character).partition { |spell| spell["always_prepared"] }
      declared_groups = character.game_table.spell_groups
      (always_prepared.any? ? [[t("#{SCOPE}.always_prepared"), always_prepared]] : []) +
        chosen.group_by { |spell| spell["level"].to_i }
              .map { |level, spells| [summary_spell_level_title(declared_groups, level), spells] }
    end

    private

    def sorted_spells(character)
      character.spells.sort_by { |spell| [spell["level"].to_i, spell["name"].to_s] }
    end

    # The label of the group of that level, with the level when the group spans several ("Sorts préparés de niveau 1")
    def summary_spell_level_title(declared_groups, level)
      declared_group = declared_groups.find { |candidate| CharacterSheets::SpellChoices.covers_level?(candidate, level) }
      return t("#{SCOPE}.level", level: level) unless declared_group
      return declared_group["label"] unless CharacterSheets::SpellChoices.several_levels?(declared_group)

      t("#{SCOPE}.group_level", group: declared_group["label"], level: level)
    end
  end
end
