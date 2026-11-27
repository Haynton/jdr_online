# The magic a game master puts on an item when giving it (Catalogs::Enchantments), as the list « Magie » of the window
# « Donner » shows it: its name, its rarity in the words of the template, and whether it requires attunement
module MagicItemsHelper
  # [label, key, data] for each magic of the table; data says what it goes on (item_gift_controller.js keeps those
  # that fit the item given)
  def enchantment_options(game_table, enchantments)
    rarity_field = game_table.current_template_fields("item_fields").find { |field| field["key"] == "rarity" }
    enchantments.map do |enchantment|
      [enchantment_label(enchantment, rarity_field), enchantment.key,
       { data: { applies_to: enchantment.properties["applies_to"],
                 keys: Catalogs::Enchantments.keys_of(enchantment).join(" ") } }]
    end
  end

  private

  def enchantment_label(enchantment, rarity_field)
    rarity = rarity_field && FieldTypes.of(rarity_field).summary_text(enchantment.properties["rarity"], rarity_field)
    details = [rarity.presence, (t("magic_items.attunement") if enchantment.properties["attunement"])].compact
    details.any? ? "#{enchantment.name} (#{details.join(', ')})" : enchantment.name
  end
end
