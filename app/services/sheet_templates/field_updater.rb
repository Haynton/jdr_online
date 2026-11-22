# Saves a field of the character sheet of a template as the game master changed it in the template editor: what the
# form sent (always text, and every setting of the field: one not sent counts as emptied) becomes the value of each
# setting, by its kind of input (FieldParameters): a whole number, a list of options (one per line), true for a
# ticked box... A setting left empty is taken out of the field (the
# template keeps only what is set), an unticked box too, except "asked at creation", whose absence means yes.
# What never changes: the key and the type (fixed), the effects and the descriptions of the options, and the options
# of a list that has effects or descriptions (renaming one would break them). The template as a whole is then checked
# (SheetTemplateValidator): false with its errors, the field left as it was in the database
module SheetTemplates
  class FieldUpdater
    def initialize(sheet_template:, field_key:, submitted_values:)
      @sheet_template = sheet_template
      @field_key = field_key
      @submitted_values = submitted_values.to_h.stringify_keys
    end

    def call
      fields = character_fields.map { |field| field["key"] == @field_key ? updated(field) : field }
      @sheet_template.character_fields = @sheet_template.character_fields.merge("fields" => fields)
      @sheet_template.save
    end

    # The settings of the field the editor may change, in the order of its type (common ones first)
    def self.editable_parameters(field)
      type = FieldTypes.of(field)
      type.parameters.reject { |parameter| fixed?(parameter, field, type) }
    end

    def self.fixed?(parameter, field, type)
      return true if FieldParameters.kind(parameter, type) == :fixed

      parameter == "options" && (field["effects"].present? || field["descriptions"].present?)
    end

    private

    def character_fields
      @sheet_template.character_fields.to_h["fields"].to_a
    end

    def updated(field)
      self.class.editable_parameters(field).each_with_object(field.dup) do |parameter, updated_field|
        value = converted(parameter, FieldParameters.kind(parameter, FieldTypes.of(field)))
        value.nil? ? updated_field.delete(parameter) : updated_field[parameter] = value
      end
    end

    # nil takes the setting out of the field. A value that cannot be converted is kept as typed: the validator of the
    # template, or the check of its type, refuses it and the form shows it again
    def converted(parameter, kind)
      typed_value = @submitted_values[parameter].to_s.strip
      case kind
      when :boolean then typed_value == "1" || nil
      when :asked_at_creation then typed_value == "1" ? nil : false
      when :integer then typed_value.presence && (Integer(typed_value, 10, exception: false) || typed_value)
      when :decimal then typed_value.presence && decimal(typed_value)
      when :lines then lines(typed_value)
      else typed_value.presence
      end
    end

    # 0,5 or 0.5; a whole number stays whole (1, not 1.0)
    def decimal(typed_value)
      number = Float(typed_value.tr(",", "."), exception: false)
      return typed_value unless number

      (number % 1).zero? ? number.to_i : number
    end

    def lines(typed_value)
      typed_value.lines.map(&:strip).compact_blank.uniq.presence
    end
  end
end
