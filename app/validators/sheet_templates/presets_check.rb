module SheetTemplates
  # The ready-made items of the template only fill fields of the item sheet
  class PresetsCheck < Check
    def call
      item_keys = fields_of("item_fields").pluck("key")
      @sheet_template.preset_items.to_a.flat_map do |preset_item|
        (preset_item["properties"].to_h.keys - item_keys).map do |property|
          [:unknown_item_property, { item: preset_item["name"], property: property }]
        end
      end
    end
  end
end
