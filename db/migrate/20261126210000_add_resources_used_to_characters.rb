# What a character has spent of the resources its options give (CharacterResources: the rages of a barbarian, the
# channel divinity of a cleric...), by key of the resource: { "rage" => 1 }. Nothing spent by default; a rest gives
# them back as the template declares
class AddResourcesUsedToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :resources_used, :jsonb, default: {}, null: false
  end
end
