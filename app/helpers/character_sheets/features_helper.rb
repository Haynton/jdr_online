# The features, traits and feats of a character, with their short summary (CharacterSheets::Features): in the summary
# of the choices of the creation, on the summary sheet and in « Mes personnages », and in the game room
module CharacterSheets
  module CharacterSheets::FeaturesHelper
    # Every feature the option of field names, each from its level: the summary of the choices shows those reached
    def choice_option_features(character, field, option)
      character_features(character).features_of(field, option)
    end

    # The groups of the features the character has (CharacterSheets::Features::Group), up to its level
    def character_feature_groups(character)
      character_features(character).call
    end

    # A feature shows once the character reaches its level: read in the level_from of its list (the subclass), else in
    # the level the table gives (from_table), as the other facts of the summary (described_choices_controller.js)
    def feature_hidden?(character, field, feature)
      choice_fact_hidden?(character, feature_level_field(character, field), feature.level)
    end

    def feature_line_data(character, field, feature)
      choice_fact_data(character, feature_level_field(character, field), feature.level)
    end

    # What a line says beside the name: the origin feat of a background, the level of a feature after the first
    def feature_note(feature)
      return t("game_tables.choice_summaries.facts.origin_feat") if feature.kind == :feat
      return if feature.level <= 1

      t("game_tables.choice_summaries.features_level", level: feature.level)
    end

    private

    def feature_level_field(character, field)
      return field if field["level_from"]

      level_field = character.sheet_fields.find { |candidate| candidate["from_table"] == "starting_level" }
      level_field ? field.merge("level_from" => level_field["key"]) : field
    end

    # One reading of the catalog per character and per page
    def character_features(character)
      @character_features ||= {}
      @character_features[character] ||= CharacterSheets::Features.new(character)
    end
  end
end
