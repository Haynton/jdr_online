// The twins, for the page, of the effects of app/models/choice_effects (ChoiceEffects) that apply while the player
// picks an option (LIVE): each one takes back the value of the option before and applies the one of the option picked,
// as its Ruby class does on the server (CharacterSheets::ChoiceEffectsApplier). Changing one means changing the other.
// An effect gets the two values and the page given by character_sheet_controller.js (tickBox, writeField)
import proficient from "choice_effects/proficient"
import set from "choice_effects/set"

// By key of the effect
const choiceEffects = { proficient, set }

export function applyChoiceEffects(previousEffects, pickedEffects, page) {
  Object.entries(choiceEffects).forEach(([effectKey, apply]) => {
    apply(previousEffects[effectKey], pickedEffects[effectKey], page)
  })
}
