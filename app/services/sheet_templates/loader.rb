# Loads a template file of db/seeds/sheet_templates (one template in one language) into sheet_templates: the
# predefined template of that name and language is created, or updated with the content of the file. Nothing is
# deleted, so it can run again after each change of the file, in production too (SheetTemplates::PredefinedLoader).
# The tables keep their own copy (template_snapshot): an update only reaches the tables created after it.
# A template renamed in its file is a new one: the one of the old name stays
module SheetTemplates
  class Loader
    def initialize(template_file)
      @template_file = Pathname(template_file)
    end

    # The template, saved (SheetTemplateValidator refuses a file that does not hold together)
    def call
      sheet_template = SheetTemplate.predefined.find_or_initialize_by(name: attributes["name"],
                                                                      locale: attributes["locale"])
      sheet_template.update!(attributes)
      sheet_template
    end

    private

    # Read as UTF-8 for its accents
    def attributes
      @attributes ||= JSON.parse(@template_file.read(encoding: "UTF-8"))
    end
  end
end
