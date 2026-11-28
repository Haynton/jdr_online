# What a player's character created above level 1 gets beside its normal starting equipment (decision of 27 November),
# by the way the table picked (TableRules#higher_level_equipment_tier, the tiers of its template): gold, part of it
# rolled by the server when the creation is done, and magic items picked at the step of the equipment, one per place
# its tier gives ({ "common" => 1, "uncommon" => 1 }: the places « common-1 », « uncommon-1 »). A place holds a magic
# item of its rarity from the catalog of the table, or a magic that goes on an item (Catalogs::Enchantments: a +1, a
# Flame Tongue) put on one item of its starting equipment (« weapon-plus-1~longsword »), kept in
# characters.starting_magic_items. Both are copied into its inventory when the creation is done
module CharacterHigherLevelEquipment
  extend ActiveSupport::Concern

  SEPARATOR = "~".freeze

  Place = Data.define(:key, :rarity, :number)
  Choice = Data.define(:value, :name)

  included do
    include CharacterHigherLevelGold

    attr_accessor :checks_starting_magic_items

    validate :starting_magic_items_picked, if: -> { pc? && (checks_starting_magic_items || completing_creation?) }
  end

  # The tier of its level, nil at level 1, without levels, or with the normal equipment only
  def higher_level_equipment_tier
    return unless levels_up?

    game_table.higher_level_equipment_tier(current_level)
  end

  # One place per magic item its tier gives, by rarity then number
  def magic_item_places
    higher_level_equipment_tier.to_h["magic_items"].to_h.flat_map do |rarity, count|
      (1..count).map { |number| Place.new(key: "#{rarity}-#{number}", rarity: rarity, number: number) }
    end
  end

  # What a place of that rarity may hold: the magic items of the table of that rarity, then each magic of that rarity
  # put on each item of its starting equipment it goes on (« Épée longue +1 »)
  def magic_item_choices(rarity)
    alone = magic_items_of(rarity).reject { |entry| Catalogs::Enchantments.enchantment?(entry) }
    alone.map { |entry| Choice.new(entry.key, entry.name) } + enchanted_choices(rarity)
  end

  # The places sent from the step ({ "common-1" => "potion-of-healing" }), only its own places kept
  def choose_starting_magic_items(picks)
    places = magic_item_places.map(&:key)
    self.starting_magic_items = picks.to_h.stringify_keys.slice(*places).compact_blank
  end

  # A class, a level or an equipment changed on another step drops what it no longer offers
  def keep_offered_magic_items
    kept = magic_item_places.to_h { |place| [place.key, starting_magic_items.to_h[place.key]] }.compact
    kept.select! { |key, value| offered_in?(key, value) }
    self.starting_magic_items = kept
  end

  # The name of a rarity, in the words of the template (the labels of the list of the items that holds it)
  def magic_item_rarity_label(rarity)
    field = game_table.current_template_fields("item_fields").find do |candidate|
      Array(candidate["options"]).include?(rarity)
    end
    return rarity.humanize unless field

    Array(field["labels"])[field["options"].index(rarity)] || rarity
  end

  # The magic items picked, as lines of its inventory, the item a magic goes on taken out of its starting equipment
  def with_starting_magic_items(items)
    starting_magic_items.to_h.each_value do |value|
      magic_key, item_key = value.split(SEPARATOR, 2)
      magic = magic_items_by_key[magic_key]
      next unless magic

      items << (item_key ? enchanted_line(items, magic, item_key) : InventoryItem.from_entry(magic, quantity: 1))
    end
    items.compact.reject { |item| item.quantity.zero? }
  end

  private

  def magic_items_of(rarity)
    table_items.select { |entry| entry.properties["rarity"] == rarity }
  end

  def magic_items_by_key
    @magic_items_by_key ||= table_items.select { |entry| entry.properties["rarity"].present? }.index_by(&:key)
  end

  def table_items
    @table_items ||= Catalogs::TableCatalog.new(game_table).entries("item").reorder(:name).to_a
  end

  def enchanted_choices(rarity)
    enchantments = Catalogs::Enchantments.new(game_table)
    starting_entries.flat_map do |item|
      enchantments.for(item).select { |magic| magic.properties["rarity"] == rarity }.map do |magic|
        Choice.new([magic.key, item.key].join(SEPARATOR), InventoryItem.from_entry(item, quantity: 1,
                                                                                         enchantment: magic).name)
      end
    end
  end

  # The items of its starting equipment as the step shows them (the default option before a choice), once each
  def starting_entries
    CharacterSheets::StartingEquipment.new(self).shown_items.map(&:entry).uniq(&:key)
  end

  def offered_in?(place_key, value)
    place = magic_item_places.find { |candidate| candidate.key == place_key }
    place && magic_item_choices(place.rarity).any? { |choice| choice.value == value }
  end

  # One of the item taken out of its line, the magic item in a line of its own, worn as the item was
  def enchanted_line(items, magic, item_key)
    line = items.find { |item| item.key == item_key && item.quantity.positive? }
    return unless line

    line.quantity -= 1
    entry = table_items.find { |candidate| candidate.key == item_key }
    return unless entry

    InventoryItem.from_entry(entry, quantity: 1, enchantment: magic).tap { |item| item.equipped = line.equipped }
  end

  def starting_magic_items_picked
    places = magic_item_places
    missing = places.reject { |place| offered_in?(place.key, starting_magic_items.to_h[place.key]) }
    missing.each do |place|
      errors.add(:starting_magic_items, :not_picked, rarity: magic_item_rarity_label(place.rarity))
    end
  end

  def completing_creation?
    complete? && status_changed?
  end
end
