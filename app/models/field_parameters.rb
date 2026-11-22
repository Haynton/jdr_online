# The settings of a field of a template, as the template editor asks them (third piece of the editor, see CLAUDE.md):
# for each setting, the kind of input it takes, and for a closed list its values. Which settings a field has is said by
# its type (FieldTypes::Base#parameters); a setting that names another field (based_on, level_from...) is a choice
# among the fields of the type its type expects (FieldTypes::Base#references). The form of the editor draws each
# setting by its kind (SheetTemplates::FieldFormHelper), SheetTemplates::FieldUpdater turns what was typed into the
# value of the JSON, and SheetTemplateValidator refuses a value out of its closed list
module FieldParameters
  KINDS = {
    "label" => :text, "abbreviation" => :text, "help" => :long_text, "section" => :section,
    "required" => :boolean, "visible_to_others" => :boolean, "summary_only" => :boolean, "internal" => :boolean,
    "short" => :boolean, "receives_damage" => :boolean,
    # A field is asked at creation unless it says false: the box is ticked by default
    "at_creation" => :asked_at_creation,
    "min" => :integer, "max" => :integer, "count" => :integer, "total" => :integer, "max_per_ability" => :integer,
    "step" => :decimal,
    "options" => :lines, "granted" => :lines,
    "column" => :choice, "from_table" => :choice, "on_rest" => :choice, "modifier" => :choice, "rule" => :choice,
    # Set once and for all: the key names the field everywhere (forms, sheets saved), the type its whole behavior;
    # the effects and the descriptions of the options will have their own editor
    "key" => :fixed, "type" => :fixed, "effects" => :fixed, "descriptions" => :fixed
  }.freeze

  # The values of each closed list, read when asked (the rules come from their registries). column: aside, the right
  # column of its section. from_table: the value the table gives (its starting level). on_rest: what a rest does
  # (back to its maximum, or switched off)
  CHOICES = {
    "column" => -> { %w[aside] }, "from_table" => -> { %w[starting_level] },
    "on_rest" => -> { %w[reset_to_max turn_off] },
    "modifier" => -> { ModifierRules.keys }, "rule" => -> { ComputedRules.keys }
  }.freeze

  # The kind of input of a setting of that type: a setting that names another field is a reference
  def self.kind(parameter, type)
    return :reference if type.references.key?(parameter)

    KINDS.fetch(parameter, :fixed)
  end

  def self.choices(parameter)
    CHOICES.fetch(parameter, -> { [] }).call
  end

  # What a value of each kind looks like in the JSON (a choice or a reference is checked against its list elsewhere)
  VALUE_CHECKS = {
    text: ->(value) { value.is_a?(String) }, long_text: ->(value) { value.is_a?(String) },
    section: ->(value) { value.is_a?(String) }, choice: ->(value) { value.is_a?(String) },
    reference: ->(value) { value.is_a?(String) },
    boolean: ->(value) { [true, false].include?(value) },
    asked_at_creation: ->(value) { [true, false].include?(value) },
    integer: ->(value) { value.is_a?(Integer) }, decimal: ->(value) { value.is_a?(Numeric) && value.positive? },
    lines: ->(value) { value.is_a?(Array) && value.all?(String) }
  }.freeze

  # Whether a value fits the kind of its setting (a fixed setting is checked by its own rules)
  def self.valid_value?(kind, value)
    VALUE_CHECKS.fetch(kind, ->(_value) { true }).call(value)
  end
end
