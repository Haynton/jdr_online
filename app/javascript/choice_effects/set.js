// ChoiceEffects::SetValues: the values of the option picked written (speed, size of a species); a field the option
// before had filled, and the new one does not, is emptied
export default function set(previousValues = {}, pickedValues = {}, page) {
  Object.keys(previousValues).filter((fieldKey) => !(fieldKey in pickedValues))
    .forEach((fieldKey) => page.writeField(fieldKey, ""))
  Object.entries(pickedValues).forEach(([fieldKey, value]) => page.writeField(fieldKey, value))
}
