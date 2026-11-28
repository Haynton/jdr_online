module SheetTemplates
  # A field shown only for some values of a list (shown_with: the damage of an item for a weapon only, FieldShownWith):
  # it names a list of the same part, and some of its options
  class ShownWithCheck < Check
    def call
      PARTS.flat_map do |part|
        fields = fields_of(part)
        fields.select { |field| field.key?("shown_with") }.filter_map do |field|
          [:invalid_shown_with, context(part, field)] unless valid?(field["shown_with"], fields)
        end
      end
    end

    private

    def valid?(shown_with, fields)
      return false unless shown_with.is_a?(Hash) && shown_with.keys.sort == %w[field values]

      list = fields.find { |field| field["key"] == shown_with["field"] && field["type"] == "choice" }
      values = shown_with["values"]
      list.present? && values.is_a?(Array) && values.any? && (values - list["options"].to_a).empty?
    end
  end
end
