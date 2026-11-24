# The rules of the game the game master picks for the table, by key ({ "ability_method" => "point_buy" }): the ways
# the template offers to play a rule (character_fields.ability_methods). Nothing picked: the first way of the template
class AddRulesToGameTables < ActiveRecord::Migration[8.1]
  def change
    add_column :game_tables, :rules, :jsonb, null: false, default: {}
  end
end
