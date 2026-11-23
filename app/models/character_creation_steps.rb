# The steps a player goes through to make their character, read from the template copied into the table
# (character_fields.creation_steps: key, label, the sections it asks, asks_name, only_with_effect, summary_only, and
# the behaviors it turns on), then the summary. A behavior adds to the step what it chooses beside its fields
# (CreationStepBehaviors: chooses_spells offers the spells of the class, chooses_equipment the starting equipment).
# A step with only_with_effect shows only when an option picked has that effect
# (spells: a class with spellcasting). A step summary_only has nothing to fill in (combat: worked out values, the speed
# given by the species; decision): it is not a page of the creation, only a block of the summary sheet. A template
# without steps (cosmic horror) asks all its fields and the name in one step. Steps are compared in the order of the
# template, conditional ones included: the step reached is kept by its key and stays in place when a conditional step
# comes or goes
class CharacterCreationSteps
  SUMMARY = "summary".freeze
  SINGLE_STEP = "sheet".freeze

  Step = Data.define(:key, :label, :fields, :asks_name, :summary_only, :behaviors) do
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
             [Step.new(key: SUMMARY, label: nil, fields: [], asks_name: false, summary_only: false, behaviors: [])]
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
    @shown_steps ||= with_fields_chosen_by_players(
      declared_steps.select { |declared| shown?(declared) }.map { |declared| build_step(declared) }
    )
  end

  # The level the table lets its players choose goes on the first page (decision), with the fields of that page
  def with_fields_chosen_by_players(steps)
    first_page = steps.find { |step| !step.summary_only }
    return steps if first_page.nil? || fields_chosen_by_players.empty?

    steps.map { |step| step == first_page ? step.with(fields: step.fields + moved_to(first_page)) : step }
  end

  # The values the table gives (from_table: the level) that its players may change, when the game master lets them
  # (players_choose_level, step Settings of the table); none otherwise
  def fields_chosen_by_players
    return [] unless @game_table.players_choose_level

    @game_table.character_sheet_fields.select { |field| field["from_table"] == "starting_level" }
  end

  # In the section of the page they join: in their own one ("Details"), they would show a title of their own there
  def moved_to(page)
    section = page.fields.first&.dig("section")
    fields_chosen_by_players.map { |field| section ? field.merge("section" => section) : field }
  end

  def declared_steps
    @game_table.character_creation_steps.presence ||
      [{ "key" => SINGLE_STEP, "sections" => creation_fields.pluck("section").uniq, "asks_name" => true }]
  end

  def build_step(declared)
    Step.new(key: declared["key"], label: declared["label"], asks_name: declared["asks_name"] == true,
             summary_only: declared["summary_only"] == true, behaviors: CreationStepBehaviors.of(declared),
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
