# An item a character carries: a copy of its catalog entry, made when the character is created (its starting
# equipment, CharacterSheets::StartingEquipment) or given by the game master in the game room
# (GameTables::ItemGiftsController), with how many of it (20 arrows)
class InventoryItem < ApplicationRecord
  # Same limit as the name column in the database
  NAME_MAX_LENGTH = 60

  belongs_to :character

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }

  # A copy of an item of the catalog, its note in its name ("Livre de prières")
  def self.copy_of(starting_item)
    from_entry(starting_item.entry, quantity: starting_item.count, note: starting_item.note)
  end

  # A copy of an entry of the catalog of the table: it never changes when the catalog does
  def self.from_entry(entry, quantity:, note: nil)
    name = [entry.name, note].compact.join(" ").truncate(NAME_MAX_LENGTH)
    new(key: entry.key, name: name, description: entry.description, properties: entry.properties, quantity: quantity)
  end
end
