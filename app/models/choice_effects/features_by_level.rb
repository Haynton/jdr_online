module ChoiceEffects
  # The features an option gives at each level, by key of the catalog of features (catalog_entries of kind feature,
  # their name and short summary: CharacterSheets::Features). A feature may carry its name too ({ "key" => "frenzy",
  # "name" => "Frénésie" }: the subclasses), shown when the catalog lacks it. The summary of the choices lists them,
  # each from its level, and the sheet those the character has
  class FeaturesByLevel < Base
    include Levels

    KEY = "features_by_level".freeze

    def value_errors(value, **)
      return [] if by_level?(value) && value.values.flatten.all? { |feature| feature?(feature) }

      [[:invalid_level_entries, { effect: KEY }]]
    end

    private

    def feature?(feature)
      feature.is_a?(String) || (feature.is_a?(Hash) && feature["key"].is_a?(String) && feature["name"].is_a?(String))
    end
  end
end
