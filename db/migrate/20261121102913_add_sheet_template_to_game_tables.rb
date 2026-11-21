# The template a table was made from, for information only: the table plays with its own copy
# (template_snapshot). Deleting the template empties this column and leaves the copy as it is
class AddSheetTemplateToGameTables < ActiveRecord::Migration[8.1]
  def change
    add_reference :game_tables, :sheet_template, foreign_key: { on_delete: :nullify }
  end
end
