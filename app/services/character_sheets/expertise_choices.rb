# The expertise a character may pick at its level (ChoiceEffects::ExpertiseChoices of the options it picked: the class):
# how many, and among which skills (those of the entries reached that name some, or any skill it is proficient in).
# Read by the step of the skills (the box « Expertise » of a row) and checked by CharacterSkillChoicesValidator
module CharacterSheets
  class ExpertiseChoices
    def initialize(character)
      @character = character
      @level = character.spell_choices.level
    end

    def allowed_count
      reached_entries.sum { |entry| entry["count"] }
    end

    # nil: any skill the character is proficient in
    def allowed_keys
      return nil if reached_entries.any? { |entry| entry["from"].nil? }

      reached_entries.flat_map { |entry| entry["from"] }.uniq
    end

    # Whether the row of this skill offers its box « Expertise »: a skill (one an option may offer, never a saving
    # throw), among those the class names when it names some
    def offered?(skill_key)
      allowed_count.positive? && @character.skill_choices.skill_keys.include?(skill_key) &&
        (allowed_keys.nil? || allowed_keys.include?(skill_key))
    end

    def picked_keys(skill_keys)
      skill_keys.select { |key| FieldTypes::Bonus.expertise?(@character.sheet[key]) }
    end

    private

    def reached_entries
      @reached_entries ||= declared_entries.select { |entry| entry["level"].to_i <= @level }
    end

    def declared_entries
      @character.sheet_fields.select { |field| field["type"] == "choice" && field["effects"] }.flat_map do |field|
        Array(field.dig("effects", @character.sheet[field["key"]].to_s, "expertise_choices"))
      end
    end
  end
end
