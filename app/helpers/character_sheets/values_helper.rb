# How the values worked out on a character sheet read (CharacterSheets::Calculator): a number as a bonus (+2, -1),
# a text as it is (hit dice: "3d8"). character_sheet_controller.js writes them the same way while the player types
# (formatBonus, formatComputed): changing one means changing both
module CharacterSheets
  module ValuesHelper
    # +2, -1, or a dash while it cannot be worked out (no score yet)
    def format_bonus(value)
      return "—" if value.nil?

      value.negative? ? value.to_s : "+#{value}"
    end

    def format_computed_value(value)
      value.is_a?(String) ? value : format_bonus(value)
    end

    # What the live calculation needs to work out a computed value, beside its rule
    def computed_value_data(field)
      return {} unless ComputedRules.of(field).live?

      { character_sheet_target: "computed", key: field["key"], rule: field["rule"], based_on: field["based_on"],
        level_from: field["level_from"], class_from: field["class_from"], proficiency: field["proficiency"] }.compact
    end
  end
end
