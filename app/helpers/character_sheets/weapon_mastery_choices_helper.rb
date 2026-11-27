# The fighting style and the weapon masteries at the step of the skills (decision of 26 November): cards like those of
# the spells, the one picked framed in brass
module CharacterSheets
  module WeaponMasteryChoicesHelper
    SCOPE = "game_tables.character_steps.weapon_mastery_choices".freeze
    CARD_CLASSES = "flex cursor-pointer gap-3 rounded-lg border border-line bg-surface px-3 py-2.5 transition-colors " \
                   "hover:bg-surface-raised has-checked:border-brass has-checked:ring-1 has-checked:ring-brass " \
                   "has-checked:ring-inset".freeze

    def weapon_mastery_card_classes
      CARD_CLASSES
    end
  end
end
