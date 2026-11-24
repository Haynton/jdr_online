class AddLimitSkillChoicesToGameTables < ActiveRecord::Migration[8.1]
  def change
    add_column :game_tables, :limit_skill_choices, :boolean, null: false, default: true
  end
end
