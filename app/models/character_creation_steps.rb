# The steps a player goes through to make their character, read from the template copied into the table
# (character_fields.creation_steps: key, label, the sections it asks, asks_name, only_with_effect, summary_only,
# chooses_spells), then the summary. A step with chooses_spells also offers the spells of the class (SpellChoices).
# A step with only_with_effect shows only when an option picked has that effect (spells: a class with spellcasting).
# A step summary_only has nothing to fill in (combat: worked out values, the speed given by the species; decision):
# it is not a page of the creation, only a block of the summary sheet.
# A template without steps (cosmic horror) asks all its fields and the name in one step.
# Steps are compared in the order of the template, conditional ones included: the step reached is kept by its key
# and stays in place when a conditional step comes or goes
class CharacterCreationSteps
  SUMMARY = "summary".freeze
  SINGLE_STEP = "sheet".freeze

  Step = Data.define(:key, :label, :fields, :asks_name, :summary_only, :chooses_spells) do
    def summary?
      key == SUMMARY
    end

    def field_keys
      fields.pluck("key")
    end

    def required_fields
      fields.select { |field| field["required"] }
    end
  end

  def initialize(game_table:, sheet:)
    @game_table = game_table
    @sheet = sheet.to_h
  end

  # The pages of the creation of this character, in order, the summary last
  def all
    @all ||= shown_steps.reject(&:summary_only) +
             [Step.new(key: SUMMARY, label: nil, fields: [], asks_name: false, summary_only: false,
                       chooses_spells: false)]
  end

  # The blocks of the summary sheet: every step shown, the ones with nothing to fill in comprised
  def summary_blocks
    shown_steps
  end

  def find(key)
    all.find { |step| step.key == key }
  end

  def first
    all.first
  end

  def after(step)
    all[all.index(step) + 1]
  end

  def before(step)
    position = all.index(step)
    all[position - 1] if position.positive?
  end

  # The furthest step reached: the last one whose rank is not after the step saved (a step saved that is not shown
  # any more, the spells of a class changed since, leads to the step before it)
  def furthest_reached(step_key)
    all.select { |step| rank(step.key) <= rank(step_key) }.last || first
  end

  # Where a step stands in the template, the conditional steps counted: the summary comes last
  def rank(key)
    keys = declared_steps.pluck("key") + [SUMMARY]
    keys.index(key) || -1
  end

  private

  def shown_steps
    @shown_steps ||= declared_steps.select { |declared| shown?(declared) }.map { |declared| build_step(declared) }
  end

  def declared_steps
    @game_table.character_creation_steps.presence ||
      [{ "key" => SINGLE_STEP, "sections" => creation_fields.pluck("section").uniq, "asks_name" => true }]
  end

  def build_step(declared)
    Step.new(key: declared["key"], label: declared["label"], asks_name: declared["asks_name"] == true,
             summary_only: declared["summary_only"] == true, chooses_spells: declared["chooses_spells"] == true,
             fields: creation_fields.select { |field| declared["sections"].to_a.include?(field["section"]) })
  end

  def shown?(declared)
    effect = declared["only_with_effect"]
    effect.nil? || picked_effects.any? { |effects| effects.key?(effect) }
  end

  # The effects of the options picked in the lists of the sheet (the class chosen, its background...)
  def picked_effects
    creation_fields.filter_map { |field| field.dig("effects", @sheet[field["key"]].to_s) }
  end

  def creation_fields
    @game_table.character_creation_fields
  end
end
