# What the window of a catalog entry shows of its values (decision of 27 November: a ring showed the 25 fields of an
# item, damage and armour class included): under its name, what it brings, the values the template marks listed
# ("Anneau · Rare · Demande un lien · CA +1"); then only the fields of its category (shown_with, FieldShownWith), the
# others hidden and left out of the form, a cell or a section with nothing shown hidden too. The page follows the
# category while it changes (shown_with_controller.js)
module GameTables
  module CatalogEntryShownHelper
    def catalog_entry_recap(fields, values)
      fields.select { |field| field["listed"] }.filter_map do |field|
        value = values.to_h[field["key"]]
        FieldTypes.of(field).listed_text(value, field) unless value.nil? || value == ""
      end.join(" · ")
    end

    def catalog_field_shown?(field, values)
      FieldShownWith.shown?(field, values)
    end

    def catalog_fields_shown?(fields, values)
      fields.any? { |field| catalog_field_shown?(field, values) }
    end

    # The fieldset around a field shown only with some values of a list: hidden and disabled (not sent) while the list
    # holds another value
    def catalog_shown_with_wrapper(field, values, &)
      condition = field["shown_with"]
      return capture(&) unless condition

      shown = catalog_field_shown?(field, values)
      data = { shown_with_target: "field", field: condition["field"], values: condition["values"].to_json }
      tag.fieldset(class: "min-w-0", hidden: !shown, disabled: !shown, data: data, &)
    end
  end
end
