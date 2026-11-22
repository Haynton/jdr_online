# The registry of the field types of a template (first piece of the template editor, see CLAUDE.md): each type is a
# class of app/models/field_types that says all about itself (how it is typed, checked, drawn, grouped, read on the
# summary), and the code asks it instead of deciding "by type" here and there. A new type: its class, and its line in
# ALL. No game in it: a type is a behavior, named after what it does
module FieldTypes
  ALL = [
    FieldTypes::Number, FieldTypes::Resource, FieldTypes::Ability, FieldTypes::AbilityBonuses, FieldTypes::Boolean,
    FieldTypes::Text, FieldTypes::Choice, FieldTypes::Picks, FieldTypes::Experience, FieldTypes::Attacks,
    FieldTypes::Bonus, FieldTypes::Computed, FieldTypes::EquipmentOption
  ].freeze

  def self.all
    @all ||= ALL.map(&:new)
  end

  def self.keys
    all.map(&:key)
  end

  # The type of that key, nil for a key the registry does not know
  def self.find(key)
    all.find { |type| type.key == key }
  end

  # The type of a field, or the unknown type (FieldTypes::Base), which refuses any value: callers never check for nil
  def self.of(field)
    find(field&.dig("type")) || unknown
  end

  def self.unknown
    @unknown ||= FieldTypes::Base.new
  end
end
