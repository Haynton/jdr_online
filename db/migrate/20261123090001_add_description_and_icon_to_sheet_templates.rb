# A template says what it is for (description, optional) and shows an icon chosen in a closed list
# (SheetTemplate::ICONS), the scroll for the templates made before
class AddDescriptionAndIconToSheetTemplates < ActiveRecord::Migration[8.1]
  def change
    add_column :sheet_templates, :description, :text
    add_column :sheet_templates, :icon, :string, null: false, default: "scroll_text"
  end
end
