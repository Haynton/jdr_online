module ChoiceEffects
  # The features an option gives at each level, by key of the future catalog (catalog_entries of kind feature): the
  # features of a class, kept for the next steps of the creation (they do nothing yet). A feature may carry its name
  # too ({ "key" => "frenzy", "name" => "Frénésie" }: the subclasses): the summary of the choices then lists them, one
  # line per level, the level with them, so that the page shows those reached by the character
  class FeaturesByLevel < Base
    include Levels

    KEY = "features_by_level".freeze

    def value_errors(value, **)
      return [] if by_level?(value) && value.values.flatten.all? { |feature| feature?(feature) }

      [[:invalid_level_entries, { effect: KEY }]]
    end

    # [label, names, level] for each level with named features
    def facts(value, _fields_by_key)
      return [] unless value.is_a?(Hash)

      value.sort_by { |level, _features| level.to_i }.filter_map do |level, features|
        names = features.to_a.filter_map { |feature| feature["name"] if feature.is_a?(Hash) }
        next if names.empty?

        [I18n.t("game_tables.choice_summaries.features_level", level: level), names.to_sentence, level.to_i]
      end
    end

    private

    def feature?(feature)
      feature.is_a?(String) || (feature.is_a?(Hash) && feature["key"].is_a?(String) && feature["name"].is_a?(String))
    end
  end
end
