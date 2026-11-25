module SheetTemplates
  # The spell slots of the template (character_fields.spell_slots, CharacterSheets::SpellSlots), when it declares them:
  # a label, only the settings it knows, the table of its counts; and every class that casts spells (spellcasting) has
  # that table, and where it gives its own label (label_from: the pact slots of heroic fantasy), a label of one line.
  # That the table gives a list of numbers per level is checked by the effect (ChoiceEffects::Spellcasting)
  class SpellSlotsCheck < Check
    PARAMETERS = %w[label help count_from label_from help_from].freeze
    REQUIRED_PARAMETERS = %w[label count_from].freeze

    def call
      slots = @sheet_template.character_fields.to_h["spell_slots"]
      return [] if slots.nil?

      declaration_errors(slots) + spellcasting_options.flat_map do |place, spellcasting|
        table_errors(slots, place, spellcasting) + class_label_errors(slots, place, spellcasting)
      end
    end

    private

    def declaration_errors(slots)
      unknown = (slots.keys - PARAMETERS).map { |parameter| [:unknown_spell_slots_parameter, { parameter: parameter }] }
      missing = REQUIRED_PARAMETERS.reject { |parameter| slots[parameter].present? }
                                   .map { |parameter| [:missing_spell_slots_parameter, { parameter: parameter }] }
      unknown + missing + label_errors(slots["label"])
    end

    def label_errors(label)
      return [] if label.nil? || valid_label?(label)

      [[:invalid_spell_slots_label, { count: LABEL_MAX_LENGTH }]]
    end

    def table_errors(slots, place, spellcasting)
      table = slots["count_from"]
      return [] if table.blank? || spellcasting.key?(table)

      [[:missing_slot_table, place.merge(table: table)]]
    end

    def class_label_errors(slots, place, spellcasting)
      own_label = spellcasting[slots["label_from"]] if slots["label_from"]
      return [] if own_label.nil? || valid_label?(own_label)

      [[:invalid_class_slots_label, place.merge(count: LABEL_MAX_LENGTH)]]
    end
  end
end
