# The skills a character picks for an option of a list that depends on another (the College of Lore of the bard: 3
# skills), on their own creation step: { "subclass" => ["arcana", "history", "nature"] }, by key of the list
class AddOptionSkillsToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :option_skills, :jsonb, null: false, default: {}
  end
end
