# Shows the properties of a catalog entry through the fields of a character sheet (character_sheets/fields), in the
# window of the step "Spells and items": those partials read a sheet (character.sheet) and the errors of its fields
# ("sheet.level"); an entry has properties and their errors ("properties.level", CatalogPropertiesValidator)
class CatalogEntrySheet
  def initialize(entry)
    @entry = entry
  end

  def sheet
    @entry.properties
  end

  def errors
    PropertyErrors.new(@entry)
  end

  # errors[:"sheet.level"] reads the errors of the property "level"
  PropertyErrors = Data.define(:entry) do
    def [](attribute)
      entry.errors[attribute.to_s.sub(/\Asheet\./, "properties.").to_sym]
    end
  end
end
