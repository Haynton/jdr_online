# The options a player's character picked in the groups of choices its class gives (decision of 27 November:
# invocations, metamagic, prey of the hunter, land of the circle), by key of the group in class_choices. Picked at the
# step of the skills (CreationStepBehaviors::ChoosesClassChoices), at a level gained (LevelUp), changed in the game
# room, checked by CharacterClassChoicesValidator against what its options offer at its level
# (CharacterSheets::ClassChoices)
module CharacterClassChoices
  extend ActiveSupport::Concern

  included do
    validates_with CharacterClassChoicesValidator
  end

  def class_choice_groups(level: nil)
    CharacterSheets::ClassChoices.new(self, level: level)
  end

  # What was sent, by group: the options ticked (a hidden empty value lets every box be unticked). Only the groups
  # offered at its level are kept, and the spells an option always prepares (a land) are copied again
  def choose_class_choices(picks_by_group, level: nil)
    offered = class_choice_groups(level: level).groups.map(&:key)
    self.class_choices = picks_by_group.to_h.slice(*offered).transform_values { |keys| Array(keys).compact_blank }
    self.spells = spell_choices.keep_offered(spells.to_a)
  end

  # A class or a level changed drops the groups it no longer gives, and what goes beyond their count
  def keep_offered_class_choices
    groups = class_choice_groups.groups
    self.class_choices = groups.to_h do |group|
      [group.key, (group.picked & group.offered_keys).first(group.allowed_count)]
    end.compact_blank
  end
end
