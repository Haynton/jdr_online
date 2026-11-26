# The fighting style and the weapon masteries of a player's character (decision of 26 November): picked at the step of
# the skills (CreationStepBehaviors::ChoosesWeaponMasteries), changed in the game room, checked by
# CharacterWeaponMasteriesValidator against what its class offers at its level (CharacterSheets::WeaponMasteries).
# The style keeps its key in fighting_style, the kinds of weapons in weapon_masteries
module CharacterWeaponMasteries
  extend ActiveSupport::Concern

  included do
    validates_with CharacterWeaponMasteriesValidator
  end

  def weapon_mastery_choices
    CharacterSheets::WeaponMasteries.new(self)
  end

  # What was sent: a style key (blank for none) and the kinds ticked (a hidden empty value lets every box be unticked)
  def choose_weapon_masteries(style_key, kind_keys)
    self.fighting_style = style_key.presence
    self.weapon_masteries = Array(kind_keys).compact_blank.uniq
  end

  # The effects of the style picked (archery: { "ranged_attack_bonus" => 2 }), {} for none
  def fighting_style_effects
    return {} unless fighting_style

    weapon_mastery_choices.fighting_styles.find { |style| style.key == fighting_style }&.effects || {}
  end

  # A class changed drops what the new one does not offer
  def keep_offered_weapon_masteries
    choices = weapon_mastery_choices
    self.fighting_style = nil unless choices.offered_styles.any? { |style| style.key == fighting_style }
    self.weapon_masteries = weapon_masteries.to_a & choices.offered_kinds.map(&:key)
  end
end
