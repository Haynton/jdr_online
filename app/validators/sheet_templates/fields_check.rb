module SheetTemplates
  # The fields of each part (the sheet of a character, of an NPC, of an item, of a spell): a key used once, a type of
  # the registry, only the settings its type declares and those it needs, references to a field of the right type,
  # known rules, descriptions and effects of options that exist, a single field that receives the damage
  class FieldsCheck < Check
    def call
      PARTS.flat_map do |part|
        fields = fields_of(part)
        duplicate_key_errors(part, fields) + damage_errors(part, fields) +
          fields.flat_map { |field| field_errors(part, field, fields) }
      end
    end

    private

    def duplicate_key_errors(part, fields)
      fields.pluck("key").tally.select { |_key, count| count > 1 }
            .map { |key, _count| [:duplicate_key, context(part).merge(key: key)] }
    end

    def damage_errors(part, fields)
      fields.count { |field| field["receives_damage"] } > 1 ? [[:several_damage_fields, context(part)]] : []
    end

    def field_errors(part, field, fields)
      type = FieldTypes.find(field["type"])
      return [[:unknown_type, context(part, field).merge(type: field["type"].to_s)]] unless type

      parameter_errors(part, field, type) + reference_errors(part, field, type, fields) +
        rule_errors(part, field, fields) + option_errors(part, field)
    end

    def parameter_errors(part, field, type)
      unknown = (field.keys - type.parameters).map do |parameter|
        [:unknown_parameter, context(part, field).merge(parameter: parameter)]
      end
      missing = type.required_parameters.reject { |parameter| field[parameter].present? }.map do |parameter|
        [:missing_parameter, context(part, field).merge(parameter: parameter)]
      end
      unknown + missing
    end

    # based_on names an ability, level_from a number... (FieldTypes::Base#references)
    def reference_errors(part, field, type, fields)
      type.references.filter_map do |parameter, expected_type|
        target = field[parameter]
        next if target.nil? || fields.find { |candidate| candidate["key"] == target }&.dig("type") == expected_type

        [:wrong_reference, context(part, field).merge(parameter: parameter, target: target,
                                                      expected: type_name(expected_type))]
      end
    end

    def rule_errors(part, field, fields)
      errors = []
      errors << [:unknown_rule, context(part, field).merge(rule: field["rule"])] if unknown_rule?(field)
      errors << [:unknown_modifier, context(part, field).merge(modifier: field["modifier"])] if unknown_modifier?(field)
      errors << [:missing_hit_die, context(part, field)] if hit_die_missing?(field, fields)
      errors + rule_parameter_errors(part, field)
    end

    # The settings its rule reads (ComputedRules::Base#required_parameters): hit_dice_by_class without class_from
    def rule_parameter_errors(part, field)
      return [] unless field["type"] == "computed"

      ComputedRules.of(field).required_parameters.reject { |parameter| field[parameter].present? }.map do |parameter|
        [:missing_parameter, context(part, field).merge(parameter: parameter)]
      end
    end

    def unknown_rule?(field)
      field["type"] == "computed" && ComputedRules.find(field["rule"]).nil?
    end

    def unknown_modifier?(field)
      field["type"] == "ability" && ModifierRules.find(field["modifier"]).nil?
    end

    def hit_die_missing?(field, fields)
      return false unless field["type"] == "computed" && ComputedRules.of(field).reads_hit_die?

      class_list = fields.find { |candidate| candidate["key"] == field["class_from"] }
      class_list && class_list["options"].to_a.any? { |option| !gives_hit_die?(class_list, option) }
    end

    def gives_hit_die?(class_list, option)
      class_list.dig("effects", option, "hit_die").is_a?(Integer)
    end

    # The descriptions and effects of a list are given for its own options
    def option_errors(part, field)
      %w[descriptions effects].flat_map do |setting|
        (field[setting].to_h.keys - field["options"].to_a).map do |option|
          [:unknown_option, context(part, field).merge(setting: setting, option: option)]
        end
      end
    end
  end
end
