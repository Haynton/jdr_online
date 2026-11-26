# What a character has spent of its spell slots (by level of spell: { "1" => 2 }) and of its hit dice (how many). A
# long rest gives them all back; the pact slots of a class that declares it come back on a short rest too
class AddSpentSlotsAndHitDiceToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :spell_slots_used, :jsonb, default: {}, null: false
    add_column :characters, :hit_dice_used, :integer, default: 0, null: false
  end
end
