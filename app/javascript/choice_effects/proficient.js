// ChoiceEffects::Proficient: the bonus fields of the option before unticked, those of the option picked ticked
export default function proficient(previousFieldKeys = [], pickedFieldKeys = [], page) {
  previousFieldKeys.forEach((fieldKey) => page.tickBox(fieldKey, false))
  pickedFieldKeys.forEach((fieldKey) => page.tickBox(fieldKey, true))
}
