# Loads every predefined template of db/seeds/sheet_templates, then their catalogs of db/seeds/catalogs (spells,
# items): created, or updated, never deleted. Run by db/seeds.rb and by bin/rails sheet_templates:load, which fills
# the production database without emptying it (decision: the seed empties the database first). All or nothing: a file
# refused leaves the database as it was
module SheetTemplates
  class PredefinedLoader
    TEMPLATES_FOLDER = "db/seeds/sheet_templates".freeze
    CATALOGS_FOLDER = "db/seeds/catalogs".freeze

    # The templates loaded
    def call
      SheetTemplate.transaction do
        templates = files_in(TEMPLATES_FOLDER).map { |template_file| Loader.new(template_file).call }
        files_in(CATALOGS_FOLDER).each { |catalog_file| Catalogs::Loader.new(catalog_file).call }
        templates
      end
    end

    private

    def files_in(folder)
      Rails.root.glob("#{folder}/*.json").sort
    end
  end
end
