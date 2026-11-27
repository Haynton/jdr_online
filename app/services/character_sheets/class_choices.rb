# What a character may pick in the groups of choices its options give (decision of 27 November, SRD 5.2.1: the
# invocations of the warlock, the metamagic of the sorcerer, the prey and tactics of the hunter, the land of the circle
# of the land): for each group the options it picked give (ChoiceEffects::ClassChoices, the class and the subclass
# added together), how many at its level, which options it may take (their level, the option they require), and what
# it picked. The groups are declared once by the template (character_fields.class_choices): no rule of a game here
module CharacterSheets
  class ClassChoices
    Option = Data.define(:key, :label, :description, :min_level, :requires, :repeatable, :effects)
    Group = Data.define(:key, :label, :help, :changes, :allowed_count, :options, :picked) do
      def offered_keys
        options.map(&:key)
      end

      def picked_options
        picked.filter_map { |key| options.find { |option| option.key == key } }
      end
    end

    def initialize(character, level: nil)
      @character = character
      @level = level || character.spell_choices.level
    end

    # The groups with something to pick at its level, in the order of the template
    def groups
      @groups ||= declared_groups.filter_map do |declared|
        count = counts_by_group[declared["key"]].to_a[@level - 1].to_i
        group(declared, count) if count.positive?
      end
    end

    def offered?
      groups.any?
    end

    # The effects of the options picked (the spells a land always prepares), [label, effects] as the options of a list
    def picked_effects
      groups.flat_map(&:picked_options).filter_map { |option| [option.label, option.effects] if option.effects.any? }
    end

    private

    def group(declared, count)
      picked = Array(@character.class_choices.to_h[declared["key"]])
      options = Array(declared["options"]).map { |option| option_of(option) }
      Group.new(key: declared["key"], label: declared["label"], help: declared["help"], changes: declared["changes"],
                allowed_count: count, options: options.select { |option| available?(option, picked) },
                picked: picked)
    end

    def option_of(option)
      Option.new(key: option["key"], label: option["label"], description: option["description"],
                 min_level: option["min_level"].to_i, requires: option["requires"],
                 repeatable: option["repeatable"] == true, effects: option["effects"].to_h)
    end

    # Its level reached, and the option it requires picked
    def available?(option, picked)
      option.min_level <= @level && (option.requires.nil? || picked.include?(option.requires))
    end

    def declared_groups
      @character.game_table.class_choices
    end

    # The counts of every option picked, added together by group (the class and its subclass)
    def counts_by_group
      @counts_by_group ||= picked_option_effects.each_with_object({}) do |effects, counts|
        effects.to_h[ChoiceEffects::ClassChoices::KEY].to_h.each do |key, by_level|
          counts[key] = by_level.each_with_index.map { |count, index| count + counts.fetch(key, [])[index].to_i }
        end
      end
    end

    def picked_option_effects
      @character.sheet_fields.filter_map do |field|
        field.dig("effects", @character.sheet[field["key"]].to_s) if field["effects"].is_a?(Hash)
      end
    end
  end
end
