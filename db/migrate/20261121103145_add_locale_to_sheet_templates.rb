# The language a predefined template is written in: the app provides each one in French and in English, and a game
# master is offered those of their language. Empty for a template made by a game master, written in their own words
class AddLocaleToSheetTemplates < ActiveRecord::Migration[8.1]
  def change
    add_column :sheet_templates, :locale, :string
  end
end
