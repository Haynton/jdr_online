# The step "Spells and items" of a table (GameTables::CatalogsController): its entries grouped (the spells by level,
# the items by category), what a line says under its name, whether the table offers it
module TableCatalogHelper
  # What the game master changes in the window of an entry
  CHANGEABLE_ATTRIBUTES = %w[name description properties].freeze

  # [title, entries] in order: the cantrips, then each level; the items by category, those without one last
  def catalog_entry_groups(entries, kind)
    kind == "spell" ? spell_level_groups(entries) : item_category_groups(entries)
  end

  # Under the name: the school of a spell, the damage of a weapon; an item of the starting equipment says whether the
  # starting equipment of the table holds it (its switch decides)
  def catalog_entry_detail(entry, starting: false, offered: true)
    return t("game_tables.catalogs.edit.starting_equipment.#{offered ? 'in' : 'out'}") if starting

    entry.properties.values_at("school", "damage").compact.first
  end

  # What the table did to an entry it lists: "added" (its own), "changed" (its copy differs from the template), nil
  # (a copy left as it was, or an entry only turned off: its switch says so)
  def catalog_entry_change(entry, originals)
    return if entry.game_table_id.nil?

    original = originals[entry.key]
    return :added unless original

    :changed if CHANGEABLE_ATTRIBUTES.any? { |attribute| entry[attribute] != original[attribute] }
  end

  def catalog_entry_offered?(game_table, entry)
    game_table.disabled_catalog_keys.to_h[entry.kind].to_a.exclude?(entry.key)
  end

  # Lowercase, without accents: "Détection" and "detection" find each other (catalog_search_controller.js)
  def catalog_search_name(entry)
    I18n.transliterate(entry.name).downcase
  end

  private

  def spell_level_groups(entries)
    entries.group_by(&:level).sort_by { |level, _spells| level.to_i }.map do |level, spells|
      [catalog_level_title(level.to_i), spells]
    end
  end

  def catalog_level_title(level)
    level.zero? ? t("game_tables.catalogs.edit.cantrips") : t("game_tables.catalogs.edit.level", level: level)
  end

  def item_category_groups(entries)
    groups = entries.group_by { |entry| entry.properties["category"] }
    named = groups.except(nil).sort_by { |category, _items| I18n.transliterate(category.to_s) }
    named + (groups[nil] ? [[t("game_tables.catalogs.edit.other_items"), groups[nil]]] : [])
  end
end
