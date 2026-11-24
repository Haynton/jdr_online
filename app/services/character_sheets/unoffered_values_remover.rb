# Takes out of a sheet the values its other values no longer offer, each field asking its type (FieldTypes::Base
# #kept_on?): the subclass goes when the class changes or the level falls under 3. Run before the effects are applied
# (CharacterSheets::ChoiceEffectsApplier), so that the effects of the value gone are taken back too. Needed on the
# server since the creation is in steps: the class may change on another step than the one of its subclass
module CharacterSheets
  class UnofferedValuesRemover
    def initialize(fields:)
      @fields = fields
    end

    def call(sheet)
      @fields.each_with_object(sheet.dup) do |field, kept_sheet|
        key = field["key"]
        next unless kept_sheet.key?(key)

        kept_sheet.delete(key) unless FieldTypes.of(field).kept_on?(kept_sheet[key], field, kept_sheet)
      end
    end
  end
end
