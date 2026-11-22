# Loads a catalog file of db/seeds/catalogs (the spells of a template, for now) into catalog_entries: the template is
# found by its name and the language of the file (heroic_fantasy_spells.fr.json: "Fantasy héroïque" in French), and
# each entry is created, or updated by its key. Run by db/seeds.rb, and usable in the console to fill an existing
# database without emptying it: Catalogs::Loader.new(Rails.root.join("db/seeds/catalogs/...")).call
module Catalogs
  class Loader
    def initialize(catalog_file)
      @catalog_file = Pathname(catalog_file)
    end

    # The entries of the file, saved
    def call
      CatalogEntry.transaction do
        catalog["entries"].map { |entry_attributes| save_entry(entry_attributes) }
      end
    end

    private

    def save_entry(entry_attributes)
      entry = sheet_template.catalog_entries.find_or_initialize_by(kind: catalog["kind"], key: entry_attributes["key"])
      entry.update!(entry_attributes.slice("name", "description", "properties"))
      entry
    end

    def sheet_template
      @sheet_template ||= SheetTemplate.predefined.find_by!(name: catalog["template"], locale: file_locale)
    end

    # The language is the part before .json: heroic_fantasy_spells.fr.json gives fr
    def file_locale
      @catalog_file.basename(".json").extname.delete_prefix(".")
    end

    # Read as UTF-8 for its accents
    def catalog
      @catalog ||= JSON.parse(@catalog_file.read(encoding: "UTF-8"))
    end
  end
end
