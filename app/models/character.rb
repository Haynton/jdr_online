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
  # What it carries: the starting equipment, copied when the character is complete
  has_many :inventory_items, dependent: :destroy

  enum :kind, {
    pc: "pc",
    npc: "npc",
    monster: "monster"
  }

  # A player character is made in steps, saved as a draft after each one (CharacterCreationSteps), and complete
  # once the player confirms the summary
  enum :status, {
    draft: "draft",
    complete: "complete"
  }

  # The name is asked at the last step: a draft may have none yet
  validates :name, presence: true, unless: :draft?
  validates :name, length: { maximum: NAME_MAX_LENGTH }
  validates :participation, presence: true, if: :pc?
  validates :participation_id, uniqueness: { message: :already_has_character }, if: :pc?
  validates_with CharacterSheetValidator
  validates_with CharacterSpellsValidator

  # The fields that must be filled in the step being saved ("required": the class, the species...),
  # checked by CharacterSheetValidator
  attr_accessor :required_sheet_fields

  # The fields of a player character sheet: those of the template copied into the table
  def sheet_fields
    game_table.character_sheet_fields
  end

  def creation_steps
    CharacterCreationSteps.new(game_table: game_table, sheet: sheet)
  end

  # What the player sent on a step replaces the values of that step only: an emptied field is removed. An option changed
  # in a list applies its effects to the other steps too (CharacterSheets::ChoiceEffectsApplier), and the starting
  # equipment and the spells its new class does not offer go. The step that chooses the spells copies those chosen
  # (spell_keys)
  def fill_step(step, sheet_values:, name: nil, spell_keys: nil)
    filled_values = CharacterSheets::Builder.new(fields: step.fields, submitted_values: sheet_values).call
    self.sheet = CharacterSheets::ChoiceEffectsApplier.new(fields: sheet_fields, previous_sheet: sheet)
                                                      .call(sheet.except(*step.field_keys).merge(filled_values))
    self.name = name if step.asks_name
    self.required_sheet_fields = step.required_fields
    # On another step, a class changed drops an equipment choice it does not offer; on the equipment step, what was
    # sent is checked instead (CharacterSheetValidator), never dropped without a word
    self.sheet = CharacterSheets::StartingEquipment.new(self).keep_offered(sheet) unless step.chooses_equipment
    return choose_spells(spell_keys) if step.chooses_spells

    self.spells = spell_choices.keep_offered(spells)
  end

  # The spells this character may choose: its class, its level (CharacterSheets::SpellChoices)
  def spell_choices
    CharacterSheets::SpellChoices.new(self)
  end

  # Once complete, the values the game will change start from what was worked out at creation (initial_from: the hit
  # points, a resource, start full; the armour class, a number; the gold), and the starting equipment becomes lines
  # of its inventory, saved with it
  def complete_creation
    calculated_values = computed_sheet_values[:values]
    initial_values = sheet_fields.select { |field| field["initial_from"] }.filter_map do |field|
      value = calculated_values[field["initial_from"]]&.to_i
      [field["key"], FieldTypes.of(field).initial_value(value)] if value
    end
    self.sheet = sheet.merge(initial_values.to_h)
    CharacterSheets::StartingEquipment.new(self).chosen_items.each { |item| inventory_items << InventoryItem.copy_of(item) }
    self.status = :complete
  end

  # The furthest step reached: never goes back, so that a step taken up again keeps the progress made
  def reach_creation_step(step_key)
    self.creation_step = step_key if creation_steps.rank(step_key) > creation_steps.rank(creation_step)
  end

  # A step reached already opens from the band of the steps; the first one is always open
  def creation_step_reached?(step)
    step == creation_steps.first || creation_steps.rank(step.key) <= creation_steps.rank(creation_step)
  end

  # The values worked out from what was typed: modifiers, level, proficiency, bonuses (never stored)
  def computed_sheet_values
    CharacterSheets::Calculator.new(fields: sheet_fields, sheet: sheet,
                                    level_thresholds: game_table.level_thresholds).call
  end

  # A copy of each spell chosen (decision: the catalog changing never changes a character). A key not offered stays as
  # a bare key, refused by CharacterSpellsValidator
  def choose_spells(spell_keys)
    choices = spell_choices
    self.spells = spell_keys.to_a.compact_blank.uniq.map do |spell_key|
      choices.copy_of(spell_key) || { "key" => spell_key }
    end
  end

  # CharacterSheetValidator adds its errors per field ("sheet.strength"), so that each one shows under its field.
  # Rails reads the refused value to build the message: it is in the sheet, not in a method of that name
  def read_attribute_for_validation(attribute)
    return super unless attribute.to_s.start_with?("sheet.")

    sheet[attribute.to_s.delete_prefix("sheet.")]
  end
end
