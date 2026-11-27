# The magic a game master puts on an item when giving it (decision of 27 November, SRD 5.2.1): the items of the catalog
# that apply to another one (applies_to: a weapon, an armour, a shield or ammunition; the +1, +2, +3, Flame Tongue,
# Mithral Armor...), offered on an item of that kind, and only on those it names (applies_to_keys: a Vorpal Sword on a
# glaive, a greatsword, a longsword or a scimitar). They are never given alone
module Catalogs
  class Enchantments
    # The kind of an item, read in what its sheet says of it (Equippable), nil for an item no magic goes on
    def self.kind_of(properties)
      return "ammunition" if properties["ammunition"]
      return "shield" if properties[Equippable::SHIELD_FIELD].present?
      return "armor" if properties[Equippable::ARMOR_FIELD].present?

      "weapon" if properties[Equippable::WEAPON_FIELD].present?
    end

    def self.enchantment?(entry)
      entry.properties["applies_to"].present?
    end

    def self.keys_of(enchantment)
      enchantment.properties["applies_to_keys"].to_s.split(",").map(&:strip).compact_blank
    end

    def initialize(game_table)
      @game_table = game_table
    end

    # Every magic of the table, by rarity then by name
    def all
      @all ||= TableCatalog.new(@game_table).entries("item").where("properties ? 'applies_to'").reorder(:name).to_a
    end

    # Those that go on that item of the catalog
    def for(item)
      kind = self.class.kind_of(item.properties)
      return [] unless kind

      all.select do |enchantment|
        keys = self.class.keys_of(enchantment)
        enchantment.properties["applies_to"] == kind && (keys.empty? || keys.include?(item.key))
      end
    end
  end
end
