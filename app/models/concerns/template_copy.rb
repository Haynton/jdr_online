# What a game table reads in the frozen copy of its template (template_snapshot): the fields of a player character
# and of an NPC, the steps of the creation of a character, its groups of spells, its levels. Empty without a template
module TemplateCopy
  extend ActiveSupport::Concern

  # The fields of a player character sheet, from the template copied into the table (none without a template)
  def character_sheet_fields
    template_snapshot.to_h.dig("character_fields", "fields") || []
  end

  # The fields of an NPC or a monster of the table, in the copy of its template
  def npc_sheet_fields
    template_snapshot.to_h.dig("npc_fields", "fields") || []
  end

  # The steps declared by the template to make a character (CharacterCreationSteps), none for a single page
  def character_creation_steps
    template_snapshot.to_h.dig("character_fields", "creation_steps") || []
  end

  # The groups of spells a character chooses from (character_fields.spell_groups: cantrips, prepared spells),
  # declared once by the template; the tables of each class say how many (CharacterSheets::SpellChoices)
  def spell_groups
    template_snapshot.to_h.dig("character_fields", "spell_groups") || []
  end

  # The levels of the template copied into the table, with the experience and the proficiency bonus of each
  def level_thresholds
    template_snapshot.to_h["level_thresholds"] || []
  end
end
