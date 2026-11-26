# The registry of the computing rules of a template (second piece of the template editor, see CLAUDE.md): the game
# master picks a rule for a computed field, never writes a formula (design notes, "Règles de jeu : choisies dans une
# liste"). Each rule is a class of app/models/computed_rules that says the settings it reads and works out its value;
# the live calculation of the page has its twin in app/javascript/computed_rules. A new rule: its class, its line in
# ALL, and its JavaScript module when it is shown while the player types
module ComputedRules
  ALL = [
    ComputedRules::ProficiencyByLevel, ComputedRules::AbilityModifier, ComputedRules::HitDiceByClass,
    ComputedRules::SpellSaveDc, ComputedRules::SpellAttackBonus, ComputedRules::HitPointsByLevel,
    ComputedRules::UnarmoredArmorClass, ComputedRules::WornArmorClass, ComputedRules::StartingGold
  ].freeze

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

  # The rule of a computed field, or the unknown rule (ComputedRules::Base), which works out nothing
  def self.of(field)
    find(field&.dig("rule")) || unknown
  end

  def self.unknown
    @unknown ||= ComputedRules::Base.new
  end
end
