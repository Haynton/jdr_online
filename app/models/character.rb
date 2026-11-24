# A character of a table: a player character (pc), one per player, made before they join the game; or an NPC or a
# monster of the game master (npc, monster), added at the step "NPCs and enemies", from the bestiary or from nothing.
# The values of the sheet are JSONB, keyed by the fields of the template copied into the table (template_snapshot: the
# player sheet for a pc, the NPC sheet otherwise): CharacterSheetValidator checks them, since the database cannot
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

  # The kinds of the characters of the game master (step "NPCs and enemies")
  GAME_MASTER_KINDS = %w[npc monster].freeze

  scope :of_game_master, -> { where(kind: GAME_MASTER_KINDS) }

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

  # The fields of its sheet in the template copied into the table: the player sheet, or the sheet of an NPC
  def sheet_fields
    pc? ? game_table.character_sheet_fields : game_table.npc_sheet_fields
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
    fill_behaviors(step, spell_keys: spell_keys)
  end

  # Saved in the background while the player fills a step (decision: nothing typed is lost, even when the tab closes):
  # what is valid is kept, a refused value keeps the one saved before (its error shows on Continue), and a required
  # field may stay empty in a draft. The step reached does not move
  def save_draft_step(step, sheet_values:, name: nil, spell_keys: nil)
    saved_values = { sheet: sheet.deep_dup, name: self.name, spells: spells.deep_dup }
    fill_step(step, sheet_values: sheet_values, name: name, spell_keys: spell_keys)
    self.required_sheet_fields = nil
    restore_refused_values(saved_values) if invalid?
    save
  end

  # Each behavior of the creation (CreationStepBehaviors) keeps what was picked on its own step, and on the other steps
  # drops what a class changed no longer offers (the starting equipment, the spells)
  def fill_behaviors(step, spell_keys:)
    CreationStepBehaviors.all.each do |behavior|
      step.behaviors.include?(behavior) ? behavior.fill(self, spell_keys: spell_keys) : behavior.keep_offered(self)
    end
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

  private

  # Each value refused by the validators goes back to the one saved before (a field of the sheet, the name, the spells)
  def restore_refused_values(saved_values)
    errors.attribute_names.each do |attribute|
      field_key = attribute.to_s.delete_prefix("sheet.")
      next restore_sheet_value(field_key, saved_values[:sheet]) unless field_key == attribute.to_s

      self[attribute] = saved_values[attribute] if saved_values.key?(attribute)
    end
  end

  def restore_sheet_value(field_key, saved_sheet)
    return self.sheet = sheet.except(field_key) unless saved_sheet.key?(field_key)

    self.sheet = sheet.merge(field_key => saved_sheet[field_key])
  end
end
