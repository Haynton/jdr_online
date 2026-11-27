# Checks a template of sheet as a whole each time it is saved (point 2 of the architecture of the template editor):
# its fields, the effects of its options, its creation steps, its groups of spells, its spell slots, its conditions
# and its ready-made items. JSONB has no check of its own, and a template written by a game master must never break
# the creation of a character. Each family of checks is a class of app/validators/sheet_templates, which reads what
# the field types declare (FieldTypes); every error is a message of the template ("Fiche du personnage › Points de
# vie : ..."), in the language of the page
class SheetTemplateValidator < ActiveModel::Validator
  CHECKS = [
    SheetTemplates::FieldsCheck, SheetTemplates::EffectsCheck, SheetTemplates::StepsCheck,
    SheetTemplates::SpellGroupsCheck, SheetTemplates::SpellSlotsCheck, SheetTemplates::RuleMethodsCheck,
    SheetTemplates::ConditionsCheck, SheetTemplates::DiceRollsCheck, SheetTemplates::WeaponAttacksCheck,
    SheetTemplates::DeathSavesCheck, SheetTemplates::FightingStylesCheck, SheetTemplates::ClassChoicesCheck,
    SheetTemplates::FeatsCheck,
    SheetTemplates::PresetsCheck
  ].freeze

  def validate(sheet_template)
    CHECKS.each do |check|
      check.new(sheet_template).call.each do |error_type, options|
        sheet_template.errors.add(:base, error_type, **options)
      end
    end
  end
end
