module ChoiceEffects
  # The options of the starting equipment of a class or a background (A: items and some gold, B: gold), picked in an
  # equipment_option field and read by CharacterSheets::StartingEquipment. Each option has its letter once, each line
  # of items is an item (key) or a choice among groups of the item sheet (choose), never both nor none
  class StartingEquipment < Base
    KEY = "starting_equipment".freeze

    def value_errors(value, item_groups: [], **)
      options = value.to_h["options"].to_a
      duplicate_letter_errors(options) + options.flat_map { |option| line_errors(option, item_groups) }
    end

    private

    def duplicate_letter_errors(options)
      options.pluck("key").tally.select { |_letter, count| count > 1 }.keys.map do |letter|
        [:duplicate_equipment_option, { letter: letter.to_s.upcase }]
      end
    end

    def line_errors(option, item_groups)
      option["items"].to_a.flat_map do |line|
        next [[:invalid_equipment_line, { letter: option["key"].to_s.upcase }]] unless item_or_choice?(line)

        (line["choose"].to_a - item_groups).map { |group| [:unknown_item_group, { group: group }] }
      end
    end

    def item_or_choice?(line)
      line["key"].present? ^ line["choose"].present?
    end
  end
end
