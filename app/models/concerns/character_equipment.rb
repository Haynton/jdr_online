# What a character wears and holds, as its rules read it (the armour class, ComputedRules::WornArmorClass): the items of
# its inventory it has equipped (Equippable), or while it is a draft its starting equipment as it will be equipped
module CharacterEquipment
  extend ActiveSupport::Concern

  # The armour class of the room (the box of the quick sheet and of « Ma fiche »). First version, written for D&D like
  # the other values of a fight (PlayerSheetPanelsHelper): the template will declare it
  ARMOR_CLASS_KEY = "armor_class".freeze

  # Worked out from what it wears when its template computes it (ComputedRules::WornArmorClass), else typed on its
  # sheet (a creature, a table made before)
  def armor_class_shown
    computed_sheet_values[:values][ARMOR_CLASS_KEY] || sheet.to_h[ARMOR_CLASS_KEY]
  end

  # The starting equipment chosen, as the lines of its inventory it becomes, equipped (Equippable.equip_starting)
  def starting_inventory
    items = CharacterSheets::StartingEquipment.new(self).chosen_items.map { |item| InventoryItem.copy_of(item) }
    items.tap { InventoryItem.equip_starting(items) }
  end

  # What it wears and holds: its inventory once complete; while a draft, its starting equipment as it will be
  # equipped. Nothing for a creature of the game master
  def equipped_items
    return [] unless pc?

    items = complete? ? inventory_items.to_a : starting_inventory
    items.select(&:equipped)
  end

  # The values of what it wears and holds, for the rules (the armour class)
  def equipped_item_properties
    equipped_items.map(&:properties)
  end
end
