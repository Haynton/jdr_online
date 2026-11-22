module ChoiceEffects
  # What an effect of an option may say about itself, with the behavior of the effects kept for later (they do
  # nothing yet). An effect changes only what differs
  class Base
    KEY = nil
    # The type of the fields its value names (proficient: bonus fields), checked by SheetTemplateValidator; nil for an
    # effect that names any field (set) or none
    TARGET_TYPE = nil
    # It has a twin in app/javascript/choice_effects, which applies it while the player picks the option
    LIVE = false

    def key
      self.class::KEY
    end

    def target_type
      self.class::TARGET_TYPE
    end

    def live?
      self.class::LIVE
    end

    # The keys of the fields of the sheet its value names
    def target_keys(_value)
      []
    end

    # The errors of its own value, [[error_type, options]], beside the fields it names (SheetTemplates::EffectsCheck
    # adds where they are). item_groups: the groups of the item sheet, for the starting equipment
    def value_errors(_value, **)
      []
    end

    # [[label, text]]: what it brings, as read in the summary of the choices (CharacterSheets::ChoiceSummariesHelper)
    def facts(_value, _fields_by_key)
      []
    end

    # Its part on the sheet when the option of the list list_key changes (CharacterSheets::ChoiceEffectsApplier): the
    # value of the option before is taken back, the one of the option picked applied (decision: replaced). nil when
    # the option has no such effect
    def apply(_sheet, _previous_value, _picked_value, **); end

    private

    def fact_label(fact)
      I18n.t("game_tables.choice_summaries.facts.#{fact}")
    end

    def labels_of(field_keys, fields_by_key)
      field_keys.to_a.filter_map { |field_key| fields_by_key.dig(field_key, "label") }
    end
  end
end
