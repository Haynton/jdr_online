# The expertise on the step of the skills (decision of 26 November): its box in a skill row, after the box of the
# proficiency (character_sheets/fields/_bonus)
module CharacterSheets
  module ExpertiseHelper
    # The box « Expertise » of a skill row, after the box of its proficiency: it sends "2", which wins over the "1"
    # (FieldTypes::Bonus#convert). Only for a skill the character may give expertise to at its level
    def sheet_expertise_check_box(character, field)
      return unless CharacterSheets::ExpertiseChoices.new(character).offered?(field["key"])

      check_box_tag(sheet_field_name(field), "2", FieldTypes::Bonus.expertise?(character.sheet[field["key"]]),
                    id: "#{sheet_field_id(field)}-expertise", class: SimpleFormFieldClasses::CHECKBOX,
                    aria: { label: t("game_tables.characters.new.expertise_for", skill: field["label"]) })
    end
  end
end
