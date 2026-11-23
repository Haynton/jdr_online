namespace :sheet_templates do
  # bin/rails sheet_templates:load, or on Heroku: heroku run bin/rails sheet_templates:load -a fumble-quest
  desc "Create or update the predefined templates and their catalogs, without deleting anything"
  task load: :environment do
    templates = SheetTemplates::PredefinedLoader.new.call
    templates.each do |sheet_template|
      puts "#{sheet_template.name} (#{sheet_template.locale}): #{sheet_template.catalog_entries.count} catalog entries"
    end
  end
end
