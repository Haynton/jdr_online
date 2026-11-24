# The registry of the ways to give a new character its starting equipment (character_fields.starting_equipment_methods
# of a template): the options of each list as they are (items or gold, the player picks), only the options with items,
# only the options of gold. One class per way in app/models/starting_equipment_methods. Like the other rules of the
# table (TableRules), a template lists those it offers, the table picks one. The first one is already the player's
# choice: this rule has no "player's choice" of its own. A new way: its class, its line in ALL
module StartingEquipmentMethods
  ALL = [StartingEquipmentMethods::Either, StartingEquipmentMethods::ItemsOnly,
         StartingEquipmentMethods::GoldOnly].freeze

  def self.all
    @all ||= ALL.map(&:new)
  end

  def self.keys
    all.map(&:key)
  end

  def self.find(key)
    all.find { |method| method.key == key }
  end
end
