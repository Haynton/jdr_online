# The steps a player goes through to make their character, read from the template copied into the table
# (character_fields.creation_steps: key, label, the sections it asks, asks_name, only_with_effect), then the summary.
# A step with only_with_effect shows only when an option picked has that effect (spells: a class with spellcasting).
# A template without steps (cosmic horror) asks all its fields and the name in one step.
# Steps are compared in the order of the template, conditional ones included: the step reached is kept by its key
# and stays in place when a conditional step comes or goes
class CharacterCreationSteps
  SUMMARY = "summary".freeze
  SINGLE_STEP = "sheet".freeze

  Step = Data.define(:key, :label, :fields, :asks_name) do
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

  # The steps of this character, in order, the summary last
  def all
    @all ||= declared_steps.select { |declared| shown?(declared) }.map { |declared| build_step(declared) } +
             [Step.new(key: SUMMARY, label: nil, fields: [], asks_name: false)]
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

  # Where a step stands in the template, the conditional steps counted: the summary comes last
  def rank(key)
    keys = declared_steps.pluck("key") + [SUMMARY]
    keys.index(key) || -1
  end

  private

  def declared_steps
    @game_table.character_creation_steps.presence ||
      [{ "key" => SINGLE_STEP, "sections" => creation_fields.pluck("section").uniq, "asks_name" => true }]
  end

  def build_step(declared)
    Step.new(key: declared["key"], label: declared["label"], asks_name: declared["asks_name"] == true,
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
