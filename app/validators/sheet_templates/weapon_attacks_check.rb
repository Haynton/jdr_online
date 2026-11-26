module SheetTemplates
  # The weapon attacks of the template (character_fields.weapon_attacks, CharacterSheets::WeaponAttacks), when it
  # declares them: only the settings it knows, the abilities of a melee and of a ranged attack, each a field of the
  # character sheet of the type it names (an ability, the computed proficiency bonus, the list whose option gives the
  # training of the class), and the words of a two-handed attack on one line
  class WeaponAttacksCheck < Check
    # The settings that name a field of the character sheet, with the type of that field
    REFERENCES = {
      "melee_ability" => "ability", "ranged_ability" => "ability", "proficiency" => "computed",
      "training_from" => "choice"
    }.freeze
    PARAMETERS = (REFERENCES.keys + %w[two_handed_label]).freeze
    REQUIRED_PARAMETERS = %w[melee_ability ranged_ability].freeze

    def call
      attacks = character_fields_settings["weapon_attacks"]
      return [] if attacks.nil?
      return [[:invalid_weapon_attacks, {}]] unless attacks.is_a?(Hash)

      parameter_errors(attacks) + reference_errors(attacks) + label_errors(attacks["two_handed_label"])
    end

    private

    def character_fields_settings
      @sheet_template.character_fields.to_h
    end

    def parameter_errors(attacks)
      unknown = (attacks.keys - PARAMETERS).map { |parameter| [:unknown_weapon_attacks_parameter, { parameter: }] }
      missing = REQUIRED_PARAMETERS.reject { |parameter| attacks[parameter].present? }
                                   .map { |parameter| [:missing_weapon_attacks_parameter, { parameter: }] }
      unknown + missing
    end

    def reference_errors(attacks)
      REFERENCES.filter_map do |parameter, type|
        key = attacks[parameter]
        next if key.nil? || keys_of_type(character_fields, type).include?(key)

        [:invalid_weapon_attacks_field, { parameter:, type: type_name(type) }]
      end
    end

    def label_errors(label)
      return [] if label.nil? || valid_label?(label)

      [[:invalid_weapon_attacks_label, { count: LABEL_MAX_LENGTH }]]
    end
  end
end
