# A player makes their character in steps, saved as a draft after each one (decision): its status, and the furthest
# step reached (a key of the creation steps of the template, never going back). The name is asked at the last step
# only, so a draft has none yet: the model requires it once the character is complete. The characters made before
# are complete
class AddCreationStateToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :status, :string, null: false, default: "complete"
    add_column :characters, :creation_step, :string
    change_column_null :characters, :name, true
    add_check_constraint :characters, "status IN ('draft', 'complete')", name: "characters_status_check"
  end
end
