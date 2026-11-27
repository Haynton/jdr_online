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

  # The values of what it wears and holds, for the rules (the armour class), without the magic of an item not attuned
  def equipped_item_properties
    equipped_items.map(&:rule_properties)
  end

  # What its magic items give the rules (Attunable): a bonus to the armour class, and the abilities they set to a score
  # (the highest of each). An armour, a shield or a weapon counts once equipped, another item while carried
  def magic_effects
    return {} unless pc? && complete?

    working = inventory_items.to_a.select { |item| item.magic_active? && (!item.equippable? || item.equipped) }
    { "armor_class_bonus" => working.sum { |item| item.properties["item_ac_bonus"].to_i },
      "abilities" => abilities_set_by(working) }
  end

  private

  def abilities_set_by(items)
    items.each_with_object({}) do |item, abilities|
      ability = item.properties["sets_ability"]
      next unless ability

      abilities[ability] = [abilities[ability].to_i, item.properties["sets_ability_score"].to_i].max
    end
  end
end
