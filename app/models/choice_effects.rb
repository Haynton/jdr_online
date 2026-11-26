# The registry of the effects an option of a list may have on the sheet (the effects of a choice field, by option:
# the class gives its hit die, ticks its saving throws...), third piece of the template editor (see CLAUDE.md). Each
# effect is a class of app/models/choice_effects that says the fields it names, checks its own value, writes what it
# brings in the summary of the choices and does its part on the sheet when the option changes; the page has the twins
# of those it applies while the player picks (app/javascript/choice_effects). Only an aid: the player can still change
# anything (decision). A new effect: its class, its line in ALL (in the order of the summary of the choices)
module ChoiceEffects
  ALL = [
    ChoiceEffects::HitDie, ChoiceEffects::HitPointsPerLevel, ChoiceEffects::Proficient, ChoiceEffects::SkillChoices,
    ChoiceEffects::ExpertiseChoices, ChoiceEffects::WeaponMastery, ChoiceEffects::FightingStyle,
    ChoiceEffects::Spellcasting, ChoiceEffects::AlwaysPreparedSpells, ChoiceEffects::AbilityBonusChoices,
    ChoiceEffects::OriginFeat, ChoiceEffects::SetValues, ChoiceEffects::UnarmoredDefense,
    ChoiceEffects::UnarmoredDefenseWithoutShield, ChoiceEffects::Training,
    ChoiceEffects::Tools, ChoiceEffects::FeaturesByLevel, ChoiceEffects::Resources, ChoiceEffects::Traits,
    ChoiceEffects::StartingEquipment
  ].freeze

  def self.all
    @all ||= ALL.map(&:new)
  end

  def self.keys
    all.map(&:key)
  end

  # The effect of that key, nil for a key the registry does not know
  def self.find(key)
    all.find { |effect| effect.key == key }
  end
end
