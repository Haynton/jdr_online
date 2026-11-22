// The twins, for the page, of the computing rules of app/models/computed_rules (ComputedRules): each one works out the
// value of a computed field while the player types, as its Ruby class does on the server. Changing one means changing
// the other. A rule gets the settings of its field (basedOn, levelFrom, classFrom, proficiency) and the reader of the
// sheet given by character_sheet_controller.js, and gives null while it cannot work out anything
import abilityModifier from "computed_rules/ability_modifier"
import hitDiceByClass from "computed_rules/hit_dice_by_class"
import hitPointsByLevel from "computed_rules/hit_points_by_level"
import proficiencyByLevel from "computed_rules/proficiency_by_level"
import spellAttackBonus from "computed_rules/spell_attack_bonus"
import spellSaveDc from "computed_rules/spell_save_dc"
import unarmoredArmorClass from "computed_rules/unarmored_armor_class"

// By key of the rule. starting_gold has none: its field is shown nowhere (ComputedRules::StartingGold)
const computedRules = {
  proficiency_by_level: proficiencyByLevel,
  ability_modifier: abilityModifier,
  hit_dice_by_class: hitDiceByClass,
  spell_save_dc: spellSaveDc,
  spell_attack_bonus: spellAttackBonus,
  hit_points_by_level: hitPointsByLevel,
  unarmored_armor_class: unarmoredArmorClass
}

// null for a rule without a twin
export function computedValue(ruleKey, settings, reader) {
  return computedRules[ruleKey]?.(settings, reader) ?? null
}
