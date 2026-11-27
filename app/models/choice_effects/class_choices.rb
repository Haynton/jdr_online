module ChoiceEffects
  # The choices of its own an option gives (decision of 27 November, SRD 5.2.1: the invocations of the warlock, the
  # metamagic of the sorcerer, the prey and the tactics of the hunter, the land of the circle of the land): how many
  # options of each group the character picks at each level, a list of 20 numbers by group of
  # character_fields.class_choices ({ "metamagic" => [0, 2, 2, ...] }), checked by SheetTemplates::ClassChoicesCheck.
  # Read by CharacterSheets::ClassChoices
  class ClassChoices < Base
    KEY = "class_choices".freeze
    LEVELS = 20

    def value_errors(value, **)
      return [] if value.is_a?(Hash) && value.values.all? { |counts| counts?(counts) }

      [[:unknown_effect_value, { effect: KEY, value: value.to_s.truncate(60) }]]
    end

    private

    def counts?(counts)
      counts.is_a?(Array) && counts.size == LEVELS && counts.all? { |count| count.is_a?(Integer) && count >= 0 }
    end
  end
end
