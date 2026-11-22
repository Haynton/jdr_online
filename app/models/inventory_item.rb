# An item a character carries: a copy of its catalog entry, made when the character is created (its starting
# equipment, CharacterSheets::StartingEquipment), with how many of it (20 arrows)
class InventoryItem < ApplicationRecord
  # Same limit as the name column in the database
  NAME_MAX_LENGTH = 60

  belongs_to :character

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }

  # A copy of an item of the catalog, its note in its name ("Livre de prières")
  def self.copy_of(starting_item)
    entry = starting_item.entry
    name = [entry.name, starting_item.note].compact.join(" ").truncate(NAME_MAX_LENGTH)
    new(key: entry.key, name: name, description: entry.description, properties: entry.properties,
        quantity: starting_item.count)
  end
end
