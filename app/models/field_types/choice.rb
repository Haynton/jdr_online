module FieldTypes
  # One option of a list. Its options may have a description (described_choices) and effects on the sheet
  # (SheetTemplate::CHOICE_EFFECTS). A list may depend on another (options_from, options_by: the subclasses of the
  # class picked) and on a level (from_level, read in level_from: the subclass from level 3): it is asked only once
  # it has options to offer, and its value goes when the other list or the level no longer offer it. With labels, a name
  # for each option, the option is a key the rules read (the training an item needs: "simple-weapons") and the page
  # shows its name ("Armes courantes")
  class Choice < Base
    KEY = "choice".freeze
    OWN_PARAMETERS = %w[options labels descriptions effects options_from options_by from_level level_from].freeze
    REQUIRED_PARAMETERS = %w[options].freeze
    REFERENCES = { "options_from" => "choice", "level_from" => "number" }.freeze
    # The settings that go together: one without the other does not work
    PAIRED_PARAMETERS = { "options_by" => "options_from", "options_from" => "options_by",
                          "from_level" => "level_from" }.freeze

    def flow_group(_field)
      :lists
    end

    def list_choices(field)
      field["options"].to_a.map { |option| [option_label(option, field), option] }
    end

    # A list whose options have effects (the class, the background) changes the sheet: fixed once complete
    def describes_character?(field)
      field["effects"].blank?
    end

    # The options this sheet offers: those the option picked in options_from gives, or all of them
    def offered_options(field, sheet)
      return field["options"].to_a unless field["options_from"]

      field.dig("options_by", sheet[field["options_from"]].to_s).to_a
    end

    def sheet_list_choices(field, sheet)
      offered_options(field, sheet).map { |option| [option_label(option, field), option] }
    end

    def summary_text(value, field)
      option_label(value, field)
    end

    def asked_on?(field, sheet)
      level_reached?(field, sheet) && (field["options_from"].nil? || offered_options(field, sheet).any?)
    end

    def kept_on?(value, field, sheet)
      asked_on?(field, sheet) && (field["options_from"].nil? || offered_options(field, sheet).include?(value))
    end

    def error_for(value, field, character: nil, **)
      options = character ? offered_options(field, character.sheet) : field["options"].to_a
      [:inclusion] unless options.include?(value)
    end

    def settings_errors(field, fields)
      paired_errors(field) + labels_errors(field) + options_by_errors(field, fields)
    end

    private

    # The name of an option, the option itself without labels
    def option_label(option, field)
      index = field["options"].to_a.index(option)
      (index && field["labels"]&.at(index)) || option
    end

    def labels_errors(field)
      return [] unless field.key?("labels")
      return [] if field["labels"].to_a.size == field["options"].to_a.size

      [[:labels_not_matching_options, { count: field["options"].to_a.size }]]
    end

    # No level typed counts as level 1, as the rules read it (CharacterSheets::SheetReader#typed_level)
    def level_reached?(field, sheet)
      return true unless field["from_level"]

      level = sheet[field["level_from"]]
      (level.is_a?(Integer) ? level : 1) >= field["from_level"].to_i
    end

    def paired_errors(field)
      PAIRED_PARAMETERS.filter_map do |parameter, partner|
        [:missing_parameter, { parameter: partner }] if field.key?(parameter) && !field.key?(partner)
      end
    end

    # Each group is given for an option of the list it depends on, and holds options of this list
    def options_by_errors(field, fields)
      parent = fields.find { |candidate| candidate["key"] == field["options_from"] }
      groups = field["options_by"]
      return [] unless parent && groups.is_a?(Hash)

      parent_errors = (groups.keys - parent["options"].to_a).map do |option|
        [:unknown_parent_option, { parent: parent["label"].to_s, option: option }]
      end
      own_errors = (groups.values.flatten - field["options"].to_a).map do |option|
        [:unknown_option, { setting: "options_by", option: option.to_s }]
      end
      parent_errors + own_errors
    end
  end
end
