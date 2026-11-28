# What the subclass picked at a level gained brings to pick in the same window (LevelUp): the skills it offers (the
# College of Lore), and the groups of choices its class does not already give (the prey of the hunter, the land of the
# circle), prepared for every subclass of the list so that the window shows them as soon as one is picked
module LevelUpSubclassChoices
  extend ActiveSupport::Concern

  # The skills that subclass offers to choose (the College of Lore: 3), 0 otherwise
  def skill_count(for_subclass = subclass)
    return 0 unless subclass_field && for_subclass.present?

    subclass_field.dig("effects", for_subclass, "skill_choices", "count").to_i
  end

  # The skills it may pick: those the subclass offers, not proficient yet
  def skill_candidates(for_subclass = subclass)
    offered = subclass_field.dig("effects", for_subclass, "skill_choices", "from").to_a
    character.sheet_fields.select do |field|
      offered.include?(field["key"]) && !FieldTypes::Bonus.proficient?(character.sheet[field["key"]])
    end
  end

  # What each subclass of the list brings to pick in this window, prepared before it is picked (decision of
  # 27 November: shown as soon as it is chosen, game_tables/level_ups/new): its skills, and the groups of choices its
  # class does not already give. Only the subclasses that bring some
  def subclass_extras
    return [] unless subclass_field

    shared = class_choice_groups_to_pick(nil).map(&:key)
    subclass_options.filter_map do |_label, option|
      groups = class_choice_groups_to_pick(option).reject { |group| shared.include?(group.key) }
      { subclass: option, groups: groups } if groups.any? || skill_count(option).positive?
    end
  end
end
