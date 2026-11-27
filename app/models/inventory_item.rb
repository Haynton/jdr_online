# An item a character carries: a copy of its catalog entry, made when the character is created (its starting
# equipment, CharacterSheets::StartingEquipment) or given by the game master in the game room
# (GameTables::ItemGiftsController), with how many of it (20 arrows); the player takes them out one by one
# (GameTables::InventoryItemsController)
class InventoryItem < ApplicationRecord
  include Equippable
  include Attunable

  # Same limit as the name column in the database
  NAME_MAX_LENGTH = 60

  belongs_to :character

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }

  # A copy of an item of the catalog, its note in its name ("Livre de prières")
  def self.copy_of(starting_item)
    from_entry(starting_item.entry, quantity: starting_item.count, note: starting_item.note)
  end

  # One fewer (an arrow shot, a potion drunk): the last one removes the line
  def take_one_away
    return destroy if quantity <= 1

    update(quantity: quantity - 1)
  end

  # A copy of an entry of the catalog of the table: it never changes when the catalog does. With a magic put on it
  # (Catalogs::Enchantments): « Épée longue +1 », « Épée longue, Langue de feu », its values and its description added
  def self.from_entry(entry, quantity:, note: nil, enchantment: nil)
    return enchanted(entry, enchantment, quantity) if enchantment

    name = [entry.name, note].compact.join(" ").truncate(NAME_MAX_LENGTH)
    new(key: entry.key, name: name, description: entry.description, properties: entry.properties, quantity: quantity)
  end

  # The +1, +2, +3 take the number after the name; another magic its own name after a comma
  def self.enchanted(entry, enchantment, quantity)
    bonus = enchantment.key.match(/-plus-(\d)\z/)
    name = bonus ? "#{entry.name} +#{bonus[1]}" : "#{entry.name}, #{enchantment.name}"
    magic = enchantment.properties.except("category", "applies_to", "applies_to_keys")
    new(key: "#{entry.key}+#{enchantment.key}", name: name.truncate(NAME_MAX_LENGTH), quantity: quantity,
        description: [entry.description, enchantment.description].compact_blank.join("\n\n"),
        properties: entry.properties.merge(magic))
  end
end
