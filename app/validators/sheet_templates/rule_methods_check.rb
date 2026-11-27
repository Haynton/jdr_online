module SheetTemplates
  # The ways the template offers to play a rule of the table (TableRules): the scores of the abilities
  # (character_fields.ability_methods, AbilityMethods), the hit points of the levels after the first
  # (character_fields.hit_point_methods, HitPointMethods), the starting equipment
  # (character_fields.starting_equipment_methods, StartingEquipmentMethods). For each rule the template declares:
  # each way of a type its registry knows, used once, with a label, only the settings its type knows and those it
  # needs, then the checks of its type (the dice, the values, the points of the scores)
  class RuleMethodsCheck < Check
    RULES = { "ability_methods" => AbilityMethods, "hit_point_methods" => HitPointMethods,
              "starting_equipment_methods" => StartingEquipmentMethods,
              "higher_level_equipment_methods" => HigherLevelEquipmentMethods }.freeze

    def call
      RULES.flat_map do |rule, registry|
        methods = @sheet_template.character_fields.to_h[rule].to_a
        duplicate_errors(rule, methods) + methods.flat_map { |method| method_errors(rule, registry, method) }
      end
    end

    private

    def duplicate_errors(rule, methods)
      methods.pluck("type").tally.select { |_type, count| count > 1 }.keys
             .map { |type| [:duplicate_rule_method, { rule: rule_name(rule), type: type }] }
    end

    def method_errors(rule, registry, method)
      rule_method = registry.find(method["type"])
      return [[:unknown_rule_method, { rule: rule_name(rule), type: method["type"].to_s }]] unless rule_method

      name = method["label"].presence || method["type"]
      label_errors(method, name) + parameter_errors(method, rule_method, name) +
        rule_method.settings_errors(method, ability_count: keys_of_type(character_fields, "ability").size)
    end

    def label_errors(method, name)
      return [] if valid_label?(method["label"])

      [[:invalid_rule_method_label, { method: name, count: LABEL_MAX_LENGTH }]]
    end

    def parameter_errors(method, rule_method, name)
      unknown = (method.keys - rule_method.parameters).map do |parameter|
        [:unknown_rule_method_parameter, { method: name, parameter: parameter }]
      end
      missing = rule_method.required_parameters.reject { |parameter| method.key?(parameter) }.map do |parameter|
        [:missing_rule_method_parameter, { method: name, parameter: parameter }]
      end
      unknown + missing
    end

    def rule_name(rule)
      I18n.t("sheet_templates.validator.rules.#{rule}")
    end
  end
end
