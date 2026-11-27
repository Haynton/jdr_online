# A character of a table: a player character (pc), one per player, made before they join the game; or an NPC, a
# monster or a companion of the game master (npc, monster, companion), added at the step "NPCs and enemies", from the
# bestiary or from nothing. A companion (a familiar, a steed, a tamed beast) is given to a player character, its
# owner: often later, since the players have no character yet when the table is created.
# The values of the sheet are JSONB, keyed by the fields of the template copied into the table (template_snapshot: the
# player sheet for a pc, the NPC sheet otherwise): CharacterSheetValidator checks them, since the database cannot
class Character < ApplicationRecord
  include CharacterAbilityMethod
  include CharacterSkillChoices
  include CharacterDraftSaving
  include CharacterHitPoints
  include CharacterInPlay
  include PlacedOnMaps
  include CharacterDescription
  include HasAvatar

  # Same limit as the name column in the database
  NAME_MAX_LENGTH = 60

  belongs_to :game_table
  # Only for a player character: the player who plays it
  belongs_to :participation, optional: true
  # What it carries: the starting equipment, copied when the character is complete
  has_many :inventory_items, dependent: :destroy
  has_many :board_tokens, dependent: :delete_all
  # Only for a companion: the player character it is given to. None yet: it stays with the game master
  belongs_to :owner_character, class_name: "Character", optional: true, inverse_of: :companions
  # The companions given to this player character: they go back to the game master when it goes
  has_many :companions, class_name: "Character", foreign_key: :owner_character_id, inverse_of: :owner_character,
                        dependent: :nullify

  enum :kind, {
    pc: "pc",
    npc: "npc",
    monster: "monster",
    companion: "companion"
  }

  # A player character is made in steps, saved as a draft after each one (CharacterCreationSteps), and complete
  # once the player confirms the summary
  enum :status, { draft: "draft", complete: "complete" }

  # The kinds of the characters of the game master (step "NPCs and enemies")
  GAME_MASTER_KINDS = %w[npc monster companion].freeze

  scope :of_game_master, -> { where(kind: GAME_MASTER_KINDS) }

  # The name is asked at the last step: a draft may have none yet
  validates :name, presence: true, unless: :draft?
  validates :name, length: { maximum: NAME_MAX_LENGTH }
  validates :participation, presence: true, if: :pc?
  validates :participation_id, uniqueness: { message: :already_has_character }, if: :pc?
  validate :owner_is_a_player_character_of_the_table, if: :owner_character
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
  # in a list applies its effects to the other steps too, and a value the others no longer offer goes (the subclass of
  # a class changed: CharacterSheets::ChoiceEffectsApplier), and the starting equipment and the spells its new
  # class does not offer go. The step that chooses the spells copies those chosen (spell_keys)
  # choices: what the behaviors of the step get (spell_keys, fighting_style, weapon_mastery_keys, class_choices)
  def fill_step(step, sheet_values:, name: nil, **choices)
    filled_values = CharacterSheets::Builder.new(fields: step.fields, submitted_values: sheet_values).call
    self.sheet = CharacterSheets::ChoiceEffectsApplier.new(fields: sheet_fields, previous_sheet: sheet)
                                                      .call(sheet.except(*step.field_keys).merge(filled_values))
    keep_feat_skills_ticked
    keep_given_ticked if pc?
    self.name = name if step.asks_name
    self.required_sheet_fields = step.required_fields
    self.checks_ability_method = step.fields.any? { |field| field["type"] == "ability" }
    self.checks_skill_choices = step.field_keys.intersect?(skill_choices.skill_keys)
    fill_behaviors(step, **choices)
  end

  # Each behavior of the creation (CreationStepBehaviors) keeps what was picked on its own step, and on the other steps
  # drops what a class changed no longer offers (the starting equipment, the spells)
  def fill_behaviors(step, **choices)
    CreationStepBehaviors.all.each do |behavior|
      step.behaviors.include?(behavior) ? behavior.fill(self, **choices) : behavior.keep_offered(self)
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
    inventory_items << starting_inventory
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
    play_state = CharacterSheets::PlayState.new(hit_point_rolls: hit_point_rolls_for_rules,
                                                equipped_items: equipped_item_properties,
                                                fighting_style_effects: fighting_style_effects, **feat_play_values)
    CharacterSheets::Calculator.new(fields: sheet_fields, sheet: sheet, level_thresholds: game_table.level_thresholds,
                                    play_state: play_state).call
  end

  # A copy of each spell chosen (decision: the catalog changing never changes a character), and of those its options
  # always prepare and its feats give. A key not offered stays as a bare key, refused by CharacterSpellsValidator
  def choose_spells(spell_keys)
    choices = spell_choices
    chosen_spells = spell_keys.to_a.compact_blank.uniq.map do |spell_key|
      choices.copy_of(spell_key) || { "key" => spell_key }
    end
    self.spells = chosen_spells + choices.always_prepared.copies + feat_spells.copies
  end

  # Only a companion has an owner, and only a player character of its own table
  def owner_is_a_player_character_of_the_table
    return errors.add(:owner_character, :only_for_companion) unless companion?
    return if owner_character.pc? && owner_character.game_table_id == game_table_id

    errors.add(:owner_character, :not_a_player_of_the_table)
  end

  # CharacterSheetValidator adds its errors per field ("sheet.strength"), so that each one shows under its field.
  # Rails reads the refused value to build the message: it is in the sheet, not in a method of that name
  def read_attribute_for_validation(attribute)
    return super unless attribute.to_s.start_with?("sheet.")

    sheet[attribute.to_s.delete_prefix("sheet.")]
  end
end
