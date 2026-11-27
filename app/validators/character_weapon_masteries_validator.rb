# Checks the fighting style and the weapon masteries of a player's character (decision of 26 November): a style its
# class offers at its level, no more kinds of weapons than it gives, and only kinds it offers
# (CharacterSheets::WeaponMasteries). Errors on fighting_style and weapon_masteries, shown above their choices
class CharacterWeaponMasteriesValidator < ActiveModel::Validator
  def validate(character)
    return unless character.pc? && (character.fighting_style.present? || character.weapon_masteries.present?)

    choices = character.weapon_mastery_choices
    check_style(character, choices)
    check_kinds(character, choices)
  end

  private

  def check_style(character, choices)
    return if character.fighting_style.blank?
    return if choices.offered_styles.any? { |style| style.key == character.fighting_style }

    character.errors.add(:fighting_style, :not_offered)
  end

  def check_kinds(character, choices)
    picked = character.weapon_masteries.to_a
    if picked.size > choices.allowed_count
      character.errors.add(:weapon_masteries, :too_many, count: choices.allowed_count)
    end
    return if (picked - choices.offered_kinds.map(&:key)).empty?

    character.errors.add(:weapon_masteries, :not_offered)
  end
end
