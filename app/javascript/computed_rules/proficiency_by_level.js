// ComputedRules::ProficiencyByLevel: the proficiency bonus of the level typed in levelFrom, as a bonus (+2)
export default function proficiencyByLevel({ levelFrom }, reader) {
  return reader.thresholdOfLevel(levelFrom)?.proficiency_bonus ?? null
}
