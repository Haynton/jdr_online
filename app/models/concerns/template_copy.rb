# What a game table reads in the frozen copy of its template (template_snapshot): the fields of a player character,
# the steps of the creation of a character, its groups of spells, its levels. Empty without a template. The fields of
# an NPC and of a catalog entry are read in the template itself (decision of 24 November: they follow their template,
# like its catalog; the rules of the players stay in the copy), the copy only once that template is deleted
module TemplateCopy
  extend ActiveSupport::Concern

  # The fields of a player character sheet, from the template copied into the table (none without a template)
  def character_sheet_fields
    template_snapshot.to_h.dig("character_fields", "fields") || []
  end

  # The fields of an NPC or a monster of the table, in its template as it is now
  def npc_sheet_fields
    current_template_fields("npc_fields")
  end

  # The fields of a part of the template (npc_fields, spell_fields...) as it is now, or in the copy once the template
  # is deleted
  def current_template_fields(column)
    fields = sheet_template&.public_send(column).to_h["fields"]
    fields || template_snapshot.to_h.dig(column, "fields") || []
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

  # The spell slots of a character, declared once by the template (character_fields.spell_slots: label, help, the
  # table of each class that counts them; CharacterSheets::SpellSlots), nil without them
  def spell_slots
    template_snapshot.to_h.dig("character_fields", "spell_slots")
  end

  # The death saving throws of a player's character (character_fields.death_saves, CharacterDeathSaves), nil for a
  # template without: in its copy, like the fields of the sheet they fill
  def death_saves
    template_snapshot.to_h.dig("character_fields", "death_saves")
  end

  # The fighting styles a class may offer (character_fields.fighting_styles, CharacterSheets::WeaponMasteries), [] for
  # a template without: in its copy, like the class that offers them
  def fighting_styles
    template_snapshot.to_h.dig("character_fields", "fighting_styles") || []
  end

  # The groups of choices classes give (character_fields.class_choices: invocations, metamagic...,
  # CharacterSheets::ClassChoices), [] for a template without: in its copy, like the classes that give them
  def class_choices
    template_snapshot.to_h.dig("character_fields", "class_choices") || []
  end

  # How the weapons of a character attack (character_fields.weapon_attacks, CharacterSheets::WeaponAttacks), nil for a
  # template without: in its copy, like the fields of the sheet they read
  def weapon_attacks
    template_snapshot.to_h.dig("character_fields", "weapon_attacks")
  end

  # The conditions of the game (character_fields.conditions: key, label, description, levels), for the characters of
  # the players and the NPCs alike. Read in the template as it is now, like the NPC sheet (decision: a table already
  # made gets them at once), in the copy once the template is deleted; none for a template that has no conditions
  def conditions
    declared = sheet_template&.character_fields.to_h["conditions"]
    declared || template_snapshot.to_h.dig("character_fields", "conditions") || []
  end

  # The dice of the game room (character_fields.dice_rolls: its modes, the die they apply to, its initiative), read in
  # the template as it is now like the conditions; none for a template that does not declare them
  def dice_rolls
    declared = sheet_template&.character_fields.to_h["dice_rolls"]
    declared || template_snapshot.to_h.dig("character_fields", "dice_rolls") || {}
  end

  # The levels of the template copied into the table, with the experience and the proficiency bonus of each
  def level_thresholds
    template_snapshot.to_h["level_thresholds"] || []
  end
end
