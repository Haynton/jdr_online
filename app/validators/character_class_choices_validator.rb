# Checks the options a player's character picked in the groups of choices of its class (decision of 27 November): only
# groups its options give at its level, no more options than they give, only options it may take (level, required
# option), each once unless it repeats (CharacterSheets::ClassChoices). An error on class_choices, shown above the
# choices
class CharacterClassChoicesValidator < ActiveModel::Validator
  def validate(character)
    return unless character.pc? && character.class_choices.present?

    groups = character.class_choice_groups.groups.index_by(&:key)
    character.class_choices.each do |group_key, picked|
      type, options = group_error(groups[group_key], Array(picked))
      character.errors.add(:class_choices, type, **options.to_h) if type
    end
  end

  private

  def group_error(group, picked)
    return [:not_offered] unless group
    return [:too_many, { group: group.label, count: group.allowed_count }] if picked.size > group.allowed_count
    return [:not_offered] unless (picked - group.offered_keys).empty?

    [:repeated, { group: group.label }] if repeated?(group, picked)
  end

  def repeated?(group, picked)
    picked.tally.any? do |key, count|
      count > 1 && !group.options.find { |option| option.key == key }&.repeatable
    end
  end
end
