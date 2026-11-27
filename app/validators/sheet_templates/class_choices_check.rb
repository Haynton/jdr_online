module SheetTemplates
  # The choices of their own that classes give (character_fields.class_choices), when the template declares them: each
  # group a key, a label, its rule (help), when it may change (CHANGES) and its options, each a key, a label, its
  # summary (description), and what may limit or repeat it (min_level, requires: another option of the group,
  # repeatable) and its effects (EFFECTS); and every group an option of a list gives (the effect class_choices) is one
  # of them
  class ClassChoicesCheck < Check
    GROUP_PARAMETERS = %w[key label help changes options].freeze
    OPTION_PARAMETERS = %w[key label description min_level requires repeatable effects].freeze
    # When the player may change a choice: at a level gained (one), after a short or a long rest
    CHANGES = %w[level_up_one short_rest long_rest].freeze
    # What an option may do to the sheet: the spells it always prepares, by level (the land of the circle)
    EFFECTS = %w[always_prepared_spells].freeze
    # An option is named like the entries of a catalog (agonizing-blast)
    OPTION_KEY_FORMAT = /\A[a-z][a-z0-9_-]*\z/

    def call
      groups = @sheet_template.character_fields.to_h["class_choices"]
      return [] if groups.nil?
      return [[:invalid_class_choices, {}]] unless groups.is_a?(Array)

      groups.flat_map { |group| group_errors(group) } + given_errors(groups)
    end

    private

    def group_errors(group)
      return [[:invalid_class_choices, {}]] unless group.is_a?(Hash)

      unknown = (group.keys - GROUP_PARAMETERS).map { |parameter| [:unknown_class_choice_parameter, { parameter: }] }
      return unknown + [[:invalid_class_choice_group, { group: group["key"].to_s }]] unless valid_group?(group)

      unknown + group["options"].flat_map { |option| option_errors(group, option) }
    end

    def valid_group?(group)
      valid_key?(group["key"]) && valid_label?(group["label"]) && CHANGES.include?(group["changes"]) &&
        group["options"].is_a?(Array) && group["options"].all?(Hash)
    end

    def option_errors(group, option)
      keys = group["options"].pluck("key")
      return [] if valid_option?(option) && (option["requires"].nil? || keys.include?(option["requires"]))

      [[:invalid_class_choice_option, { group: group["label"], option: option["key"].to_s }]]
    end

    def valid_option?(option)
      (option.keys - OPTION_PARAMETERS).empty? && option["key"].to_s.match?(OPTION_KEY_FORMAT) &&
        valid_label?(option["label"]) && option["description"].is_a?(String) &&
        (option["min_level"].nil? || option["min_level"].in?(1..20)) &&
        (option.to_h["effects"].to_h.keys - EFFECTS).empty?
    end

    def given_errors(groups)
      keys = groups.filter_map { |group| group["key"] if group.is_a?(Hash) }
      character_fields.select { |field| field["effects"] }.flat_map do |field|
        field["effects"].flat_map do |option, effects|
          (effects.to_h["class_choices"].to_h.keys - keys).map do |group|
            [:unknown_class_choice_group, context("character_fields", field).merge(option: option, group: group)]
          end
        end
      end
    end
  end
end
