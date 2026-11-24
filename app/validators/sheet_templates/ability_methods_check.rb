module SheetTemplates
  # The ways to get the scores of the abilities (character_fields.ability_methods, AbilityMethods), when the template
  # offers some: each of a type the registry knows, used once, with a label, only the settings its type knows and
  # those it needs, then the checks of its type (its dice, its values, its points)
  class AbilityMethodsCheck < Check
    def call
      methods = @sheet_template.character_fields.to_h["ability_methods"].to_a
      return [] if methods.empty?

      duplicate_errors(methods) + methods.flat_map { |method| method_errors(method) }
    end

    private

    def duplicate_errors(methods)
      methods.pluck("type").tally.select { |_type, count| count > 1 }.keys
             .map { |type| [:duplicate_ability_method, { type: type }] }
    end

    def method_errors(method)
      ability_method = AbilityMethods.find(method["type"])
      return [[:unknown_ability_method, { type: method["type"].to_s }]] unless ability_method

      name = method["label"].presence || method["type"]
      label_errors(method, name) + parameter_errors(method, ability_method, name) +
        ability_method.settings_errors(method, ability_count: keys_of_type(character_fields, "ability").size)
    end

    def label_errors(method, name)
      return [] if valid_label?(method["label"])

      [[:invalid_ability_method_label, { method: name, count: LABEL_MAX_LENGTH }]]
    end

    def parameter_errors(method, ability_method, name)
      unknown = (method.keys - ability_method.parameters).map do |parameter|
        [:unknown_ability_method_parameter, { method: name, parameter: parameter }]
      end
      missing = ability_method.required_parameters.reject { |parameter| method.key?(parameter) }.map do |parameter|
        [:missing_ability_method_parameter, { method: name, parameter: parameter }]
      end
      unknown + missing
    end
  end
end
