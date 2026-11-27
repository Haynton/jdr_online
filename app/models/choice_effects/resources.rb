module ChoiceEffects
  # The resources an option gives (decision of 26 November: those of the 12 classes of the SRD 5.2.1 and of the
  # subclasses that have some), spent in the game room and given back by a rest (CharacterResources): each one a key,
  # a label in the words of the game, how many it has (uses: a number for each level of the character, 0 before it
  # comes; or uses_from: the modifier of an ability, at least 1, from from_level), how it comes back (recovery, a
  # closed list: all after a long rest, all after a short or a long rest, one after a short rest and all after a long
  # one), from which level it also comes back after a short rest (short_rest_from_level: the bardic inspiration), and
  # whether it is spent by an amount (pool: the lay on hands). The names go in the summary of the choices
  class Resources < Base
    KEY = "resources".freeze
    TARGET_TYPE = "ability".freeze
    RECOVERIES = %w[long_rest short_rest short_rest_one].freeze
    PARAMETERS = %w[key label uses uses_from from_level recovery short_rest_from_level pool].freeze
    LEVELS = 20

    def target_keys(value)
      Array(value).filter_map { |resource| resource["uses_from"] if resource.is_a?(Hash) }
    end

    def value_errors(value, **)
      return [[:unknown_effect_value, { effect: KEY, value: value.to_s }]] unless value.is_a?(Array)

      invalid = value.reject { |resource| valid_resource?(resource) }.map { |resource| resource.to_s.truncate(60) }
      (invalid + duplicate_keys(value)).map { |shown| [:unknown_effect_value, { effect: KEY, value: shown }] }
    end

    def facts(value, _fields_by_key)
      names = Array(value).filter_map { |resource| resource["label"] if resource.is_a?(Hash) }
      names.any? ? [[fact_label(:resources), names.to_sentence]] : []
    end

    private

    def duplicate_keys(value)
      keys = value.filter_map { |resource| resource["key"] if resource.is_a?(Hash) }
      keys.select { |key| keys.count(key) > 1 }.uniq
    end

    def valid_resource?(resource)
      resource.is_a?(Hash) && (resource.keys - PARAMETERS).empty? && valid_name?(resource) &&
        RECOVERIES.include?(resource["recovery"]) && valid_uses?(resource)
    end

    def valid_name?(resource)
      resource["key"].to_s.match?(/\A[a-z][a-z0-9_]*\z/) && resource["label"].is_a?(String) &&
        resource["label"].strip.present?
    end

    # A table of a whole number for each level, or an ability whose modifier gives the uses
    def valid_uses?(resource)
      table = resource["uses"]
      return resource["uses_from"].is_a?(String) && table.nil? if table.nil? || resource.key?("uses_from")

      table.is_a?(Array) && table.size == LEVELS && table.all? { |count| count.is_a?(Integer) && !count.negative? }
    end
  end
end
