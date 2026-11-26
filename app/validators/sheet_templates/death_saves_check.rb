module SheetTemplates
  # The death saving throws of the template (character_fields.death_saves, CharacterDeathSaves), when it declares
  # them: a label, only the settings it knows, a die the room can roll, whole numbers for the roll that succeeds,
  # how many end it, the roll that counts twice as a failure (critical_failure) and the one that gives back 1 hit point
  # (critical_success), and the two number fields of the character sheet that keep the successes and the failures
  class DeathSavesCheck < Check
    # The settings that name a number field of the character sheet
    REFERENCES = %w[successes_from failures_from].freeze
    NUMBERS = %w[success_from needed critical_failure critical_success].freeze
    PARAMETERS = (REFERENCES + NUMBERS + %w[label help sides massive_damage]).freeze
    REQUIRED_PARAMETERS = (%w[label sides success_from needed] + REFERENCES).freeze

    def call
      death_saves = @sheet_template.character_fields.to_h["death_saves"]
      return [] if death_saves.nil?
      return [[:invalid_death_saves, {}]] unless death_saves.is_a?(Hash)

      parameter_errors(death_saves) + value_errors(death_saves) + reference_errors(death_saves)
    end

    private

    def parameter_errors(death_saves)
      unknown = (death_saves.keys - PARAMETERS).map { |parameter| [:unknown_death_saves_parameter, { parameter: }] }
      missing = REQUIRED_PARAMETERS.reject { |parameter| death_saves[parameter].present? }
                                   .map { |parameter| [:missing_death_saves_parameter, { parameter: }] }
      unknown + missing
    end

    def value_errors(death_saves)
      errors = []
      errors << [:invalid_death_saves_label, { count: LABEL_MAX_LENGTH }] unless valid_label?(death_saves["label"])
      errors += sides_errors(death_saves["sides"])
      errors + NUMBERS.filter_map do |parameter|
        value = death_saves[parameter]
        [:invalid_death_saves_number, { parameter: }] unless value.nil? || (value.is_a?(Integer) && value.positive?)
      end
    end

    def sides_errors(sides)
      return [] if sides.nil? || DiceRolls::Roller::SIDES.include?(sides)

      [[:invalid_death_saves_sides, { sides: DiceRolls::Roller::SIDES.join(", ") }]]
    end

    def reference_errors(death_saves)
      REFERENCES.filter_map do |parameter|
        key = death_saves[parameter]
        next if key.nil? || keys_of_type(character_fields, "number").include?(key)

        [:invalid_death_saves_field, { parameter:, type: type_name("number") }]
      end
    end
  end
end
