# The features, traits and feats a character has (decision of 26 November; the feats taken at a level gained and the
# options of the groups of choices of its class since 27 November): those the options it picked name in their
# effects (features_by_level of the class and the subclass, traits of the species, origin_feat of the background),
# up to its level, read with their name and short summary in the catalog of features of its table
# (Catalogs::TableCatalog, kind feature: our words, in the language of the template). No rule of a game is written
# here: an option names its features, the catalog says what they are
module CharacterSheets
  class CharacterSheets::Features
    # A feature named by an option, from a level of the character (1 for a trait or a feat), with the name the option
    # gives it, if any (the subclasses). Its kind: feature (of a class), trait (of a species) or feat (of a background)
    Named = Data.define(:key, :level, :name, :kind)
    # A feature with what the catalog says of it; the name the option gives when the catalog lacks it
    Feature = Data.define(:key, :level, :name, :description, :kind)
    # The features one option picked gives: its list (Classe), its option (Rôdeur)
    Group = Data.define(:label, :option, :features)

    # The features the effects of one option name, in their order: those by level first, by level. A feature named at
    # several levels (Ability Score Improvement at 4, 8, 12...) once, at its first: its summary says when it comes back
    def self.keys_of(effects)
      by_level = effects.to_h["features_by_level"].to_h.sort_by { |level, _features| level.to_i }
      named = by_level.flat_map do |level, features|
        features.to_a.map { |feature| named_feature(feature, level.to_i) }
      end
      (named + once_named(effects.to_h)).uniq(&:key)
    end

    def self.named_feature(feature, level)
      return Named.new(key: feature, level: level, name: nil, kind: :feature) unless feature.is_a?(Hash)

      Named.new(key: feature["key"], level: level, name: feature["name"], kind: :feature)
    end

    def self.once_named(effects)
      traits = effects["traits"].to_a.map { |key| Named.new(key: key, level: 1, name: nil, kind: :trait) }
      feat = effects["origin_feat"]
      feat ? traits + [Named.new(key: feat["key"], level: 1, name: feat["name"], kind: :feat)] : traits
    end

    def initialize(character)
      @character = character
    end

    # A group per list with an option picked that names features, in the order of the sheet, then a group per group of
    # choices of the class with options picked (its invocations, its metamagic); none without
    def call
      list_groups + class_choice_groups + feat_groups
    end

    def list_groups
      picked_options.filter_map do |field, option|
        reached = self.class.keys_of(field.dig("effects", option)).select { |named| named.level <= level }
        next if reached.empty?

        Group.new(label: field["label"], option: option, features: reached.map { |named| feature(named) })
      end
    end

    # Every feature of every option of field, with its catalog name and summary: the summary of the choices shows them
    # all, from their level
    def features_of(field, option)
      self.class.keys_of(field.dig("effects", option)).map { |named| feature(named) }
    end

    private

    # The feats taken (beside the origin feat of the background, shown with it), by their category (« Don général »)
    def feat_groups
      feats = @character.feat_list
      # The spells of the origin feat of the background are kept with it, the feat itself shows with the background
      entries = feats.taken_entries.reject { |entry| entry["source"] == CharacterFeats::BACKGROUND_SOURCE }
      taken = entries.filter_map { |entry| feats.find(entry["key"]) }
      taken.group_by { |feat| feats.category_label(feat) }.map do |label, category_feats|
        features = category_feats.map do |feat|
          Feature.new(key: feat.key, level: 1, name: feat.name, description: feat.description, kind: :feat_taken)
        end
        Group.new(label: label, option: nil, features: features)
      end
    end

    def class_choice_groups
      @character.class_choice_groups.groups.filter_map do |group|
        options = group.picked_options
        next if options.empty?

        features = options.map do |option|
          Feature.new(key: option.key, level: 1, name: option.label, description: option.description, kind: :choice)
        end
        Group.new(label: group.label, option: nil, features: features)
      end
    end

    def picked_options
      @character.sheet_fields.filter_map do |field|
        option = @character.sheet[field["key"]]
        [field, option] if field["effects"].is_a?(Hash) && field.dig("effects", option.to_s)
      end
    end

    def feature(named)
      entry = catalog[named.key]
      Feature.new(key: named.key, level: named.level, name: entry&.name || named.name || named.key.humanize,
                  description: entry&.description, kind: named.kind)
    end

    def catalog
      @catalog ||= Catalogs::TableCatalog.new(@character.game_table).entries("feature").index_by(&:key)
    end

    def level
      @level ||= @character.spell_choices.level
    end
  end
end
