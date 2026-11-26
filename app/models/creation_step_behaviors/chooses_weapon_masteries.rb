module CreationStepBehaviors
  # The step offers the fighting style and the weapon masteries of the class at the level of the character
  # (CharacterSheets::WeaponMasteries), and keeps those picked (decision of 26 November: at the step of the skills)
  class ChoosesWeaponMasteries < Base
    KEY = "chooses_weapon_masteries".freeze

    def form_partial
      "game_tables/character_steps/weapon_mastery_choices"
    end

    def summary_partial
      "character_sheets/summary/weapon_masteries"
    end

    def fill(character, fighting_style: nil, weapon_mastery_keys: nil, **)
      character.choose_weapon_masteries(fighting_style, weapon_mastery_keys)
    end

    # A class changed on another step drops the style and the kinds it does not offer
    def keep_offered(character)
      character.keep_offered_weapon_masteries
    end
  end
end
