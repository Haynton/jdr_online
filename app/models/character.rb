# A character of a table. For now only the player characters (pc): one per player, made before they join the game.
# The NPCs and monsters of the game master (npc, monster) come with their milestone (P4).
# The values of the sheet are JSONB, keyed by the fields of the template copied into the table (template_snapshot):
# CharacterSheetValidator checks them, since the database cannot
class Character < ApplicationRecord
  # Same limit as the name column in the database
  NAME_MAX_LENGTH = 60

  belongs_to :game_table
  # Only for a player character: the player who plays it
  belongs_to :participation, optional: true

  enum :kind, {
    pc: "pc",
    npc: "npc",
    monster: "monster"
  }

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :participation, presence: true, if: :pc?
  validates :participation_id, uniqueness: { message: :already_has_character }, if: :pc?
  validates_with CharacterSheetValidator

  # The fields of a player character sheet: those of the template copied into the table
  def sheet_fields
    game_table.character_sheet_fields
  end

  # The values worked out from what was typed: modifiers, level, proficiency, bonuses (never stored)
  def computed_sheet_values
    CharacterSheetCalculator.new(fields: sheet_fields, sheet: sheet, level_thresholds: game_table.level_thresholds).call
  end

  # CharacterSheetValidator adds its errors per field ("sheet.strength"), so that each one shows under its field.
  # Rails reads the refused value to build the message: it is in the sheet, not in a method of that name
  def read_attribute_for_validation(attribute)
    return super unless attribute.to_s.start_with?("sheet.")

    sheet[attribute.to_s.delete_prefix("sheet.")]
  end
end
