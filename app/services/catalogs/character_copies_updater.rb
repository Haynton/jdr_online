# Applies the spells and items the game master changed for a table to the characters already made: each copy a
# character keeps (a spell of characters.spells, a line of inventory_items) with the key of an entry of the table
# (its copy of a template entry, or its own) takes that entry's name, values and description. An entry turned off
# stays on the sheets that have it: a character does not lose what it chose. An item keeps its note ("Livre de
# prières"). Says how many characters changed
module Catalogs
  class CharacterCopiesUpdater
    def initialize(game_table)
      @game_table = game_table
    end

    # The characters of the players holding a copy unlike the table's version of its entry
    def characters_to_update
      @characters_to_update ||= player_characters.select { |character| holds_an_outdated_copy?(character) }
    end

    def call
      characters = characters_to_update
      Character.transaction { characters.each { |character| update_copies(character) } }
      characters.size
    end

    private

    def player_characters
      @game_table.characters.where(kind: "pc").includes(:inventory_items)
    end

    def holds_an_outdated_copy?(character)
      character.spells.to_a.any? { |spell| updated_spell(spell) != spell } ||
        character.inventory_items.any? { |item| updated_item_values(item) != current_item_values(item) }
    end

    def update_copies(character)
      character.update_columns(spells: character.spells.to_a.map { |spell| updated_spell(spell) })
      character.inventory_items.each { |item| update_item(item) }
    end

    def updated_spell(spell)
      entry = table_entries("spell")[spell["key"]]
      return spell unless entry

      spell.merge("name" => entry.name, "level" => entry.level, "description" => entry.description,
                  "properties" => entry.properties)
    end

    def update_item(item)
      item.update!(updated_item_values(item))
    end

    def current_item_values(item)
      { name: item.name, description: item.description, properties: item.properties }
    end

    def updated_item_values(item)
      entry = table_entries("item")[item.key]
      return current_item_values(item) unless entry

      name = [entry.name, item_note(item)].compact_blank.join(" ").truncate(InventoryItem::NAME_MAX_LENGTH)
      { name: name, description: entry.description, properties: entry.properties }
    end

    # What follows the catalog name in the item's name, written when it was copied (InventoryItem.copy_of)
    def item_note(item)
      former_name = [template_entries("item")[item.key]&.name, table_entries("item")[item.key].name]
                    .compact.find { |name| item.name.start_with?("#{name} ") }
      former_name && item.name.delete_prefix("#{former_name} ")
    end

    # The entries of the table itself, by key
    def table_entries(kind)
      @table_entries ||= {}
      @table_entries[kind] ||= @game_table.catalog_entries.where(kind: kind).index_by(&:key)
    end

    def template_entries(kind)
      return {} unless @game_table.sheet_template

      @template_entries ||= {}
      @template_entries[kind] ||= @game_table.sheet_template.catalog_entries.where(kind: kind).index_by(&:key)
    end
  end
end
