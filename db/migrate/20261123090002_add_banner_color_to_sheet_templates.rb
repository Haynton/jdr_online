# The color of the banner of a template, chosen in a closed list (SheetTemplate::BANNER_COLORS), gold for the
# templates made before
class AddBannerColorToSheetTemplates < ActiveRecord::Migration[8.1]
  def change
    add_column :sheet_templates, :banner_color, :string, null: false, default: "gold"
  end
end
