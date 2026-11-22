# The registry of the modifier rules of an ability (the modifier setting of an ability field): how a score gives its
# modifier, one class per rule in app/models/modifier_rules, its twin for the page in app/javascript/modifier_rules.
# Another game can have its own rule without touching the templates that use this one. A new rule: its class, its line
# in ALL, its JavaScript module
module ModifierRules
  ALL = [ModifierRules::HalfAboveTen].freeze

  def self.all
    @all ||= ALL.map(&:new)
  end

  def self.keys
    all.map(&:key)
  end

  # The rule of that key, nil for a key the registry does not know
  def self.find(key)
    all.find { |rule| rule.key == key }
  end

  # The modifier of a score by that rule. nil without a score, or for a rule the registry does not know
  def self.modifier(score, rule_key)
    return unless score.is_a?(Integer)

    find(rule_key)&.modifier(score)
  end
end
