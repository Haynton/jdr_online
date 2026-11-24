# The attacks of an NPC or a monster (FieldTypes::Attacks), one line each (character_sheets/fields/_attacks and
# _attack_line), added and removed in the page by repeated_lines_controller.js
module CharacterSheets
  module AttacksHelper
    # The placeholder of the position of a line added in the page (repeated_lines_controller.js replaces it)
    NEW_LINE_INDEX = "NEW_LINE".freeze
    # Where each part of an attack sits on its line: the name across on a phone, then two by two; on one line from
    # 672 px of line (name, bonus to hit, damage, range, "Remove")
    ATTACK_PART_CLASSES = { "name" => "col-span-2 @2xl:col-span-1", "to_hit" => "", "damage" => "",
                            "range" => "col-span-2 @2xl:col-span-1" }.freeze

    def attack_part_classes(part)
      ATTACK_PART_CLASSES.fetch(part)
    end
  end
end
