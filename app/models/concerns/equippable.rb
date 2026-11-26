# What an item of the inventory is to the rules, read in the values its catalog entry gives it (the fields of the item
# sheet of the template): an armour has a base armour class, a shield a bonus to it, a weapon its damage dice. Equipped
# (decision of 26 November: a switch « Équipé » in the inventory), an armour and a shield count in the armour class,
# one of each at a time, and each weapon gives an attack. At the end of the creation, the starting equipment is
# equipped: its first armour, its first shield, all its weapons
module Equippable
  extend ActiveSupport::Concern

  # The fields of the item sheet that say what an item is (the heroic fantasy declares them)
  ARMOR_FIELD = "armor_base".freeze
  SHIELD_FIELD = "armor_bonus".freeze
  # The most of the Dexterity modifier an armour lets count (none: all of it, a light armour)
  DEXTERITY_CAP_FIELD = "armor_dexterity_cap".freeze
  WEAPON_FIELD = "damage_dice".freeze
  # Worn one at a time: equipping one takes the other off
  WORN_FIELDS = [ARMOR_FIELD, SHIELD_FIELD].freeze

  class_methods do
    # The starting equipment of a character just complete, before it is saved
    def equip_starting(items)
      WORN_FIELDS.each { |field| items.find { |item| item.properties[field].present? }&.equipped = true }
      items.select(&:weapon?).each { |weapon| weapon.equipped = true }
    end
  end

  def armor?
    properties[ARMOR_FIELD].present?
  end

  def shield?
    properties[SHIELD_FIELD].present?
  end

  def weapon?
    properties[WEAPON_FIELD].present?
  end

  def equippable?
    armor? || shield? || weapon?
  end

  def equip(equipped)
    transaction do
      take_off_the_same_kind if equipped
      update!(equipped: equipped)
    end
  end

  private

  def take_off_the_same_kind
    worn_field = WORN_FIELDS.find { |field| properties[field].present? }
    return unless worn_field

    same_kind = character.inventory_items.where.not(id: id).where("properties ? :field", field: worn_field)
    same_kind.update_all(equipped: false)
  end
end
