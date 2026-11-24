# The filters beside the search of the windows of a catalog and of the bestiary (decision: lists, not pills): one list
# per field the template marks "filter": true (the level and the school of a spell, the category of an item, the
# challenge rating and the type of a creature), offering only the values the entries listed have, in the order of the
# field. catalog_search_controller.js hides the entries that don't match, with the search
module CatalogFiltersHelper
  CatalogFilter = Data.define(:key, :label, :choices)

  def catalog_filters(fields, entries)
    fields.select { |field| field["filter"] }.filter_map do |field|
      present = entries.map { |entry| entry.properties[field["key"]].to_s }.uniq
      choices = filter_choices(field).select { |_label, value| present.include?(value.to_s) }
      CatalogFilter.new(key: field["key"], label: field["label"], choices: choices) if choices.size > 1
    end
  end

  # The keys of the fields the template filters on
  def catalog_filter_keys(fields)
    fields.select { |field| field["filter"] }.pluck("key")
  end

  # The values of an entry for each filter, as text: { "school" => "Évocation", "level" => "3" }
  def catalog_filter_values(entry, filter_keys)
    filter_keys.to_h { |key| [key, entry.properties[key].to_s] }.to_json
  end

  private

  # A list gives its options; a number with names its names ("Cantrip", "Level 1")
  def filter_choices(field)
    FieldTypes.of(field).list_choices(field).to_a
  end
end
