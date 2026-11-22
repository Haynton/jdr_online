module ComputedRules
  # What a computing rule may say about itself. The unknown rule (a key the registry does not know) is this class
  # itself: it works out nothing
  class Base
    KEY = nil
    # The settings of its computed field it reads (FieldTypes::Computed: based_on, level_from, class_from,
    # proficiency): without them, it cannot work out anything (SheetTemplateValidator refuses the template)
    REQUIRED_PARAMETERS = [].freeze
    # It reads the hit die of the class chosen (hit_die in the effects of the list class_from): every class gives one
    READS_HIT_DIE = false
    # It has a twin in app/javascript/computed_rules, which works it out while the player types
    LIVE = true

    def key
      self.class::KEY
    end

    def required_parameters
      self.class::REQUIRED_PARAMETERS
    end

    def reads_hit_die?
      self.class::READS_HIT_DIE
    end

    def live?
      self.class::LIVE
    end

    # The value of its field, read from the sheet (CharacterSheets::SheetReader): a number reads as a bonus (+2), a text
    # as it is ("3d8", "13"). nil while it cannot be worked out (no class chosen, no score typed)
    def value(_field, _reader)
      nil
    end
  end
end
