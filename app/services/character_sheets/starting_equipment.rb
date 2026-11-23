# The starting equipment of a character (rules of 2024): each list with a starting_equipment effect (the class, the
# background) offers options, A (items and some gold) or B (gold), sometimes C; the player picks one per field of type
# equipment_option, stored as { "option" => "a", "picks" => { "2" => "lute" } }. A line of an option may be an item
# "of your choice" (choose: groups of the catalog, the musical instruments...): its pick is kept under the position
# of the line. The items come from the catalog of the table (Catalogs::TableCatalog, kind item)
module CharacterSheets
  class CharacterSheets::StartingEquipment
    # One equipment_option field: the option picked in its list (the class "Magicien"), the options it offers, the
    # option chosen (nil before a choice) and its picks
    Choice = Data.define(:field, :source_option, :options, :chosen_key, :picks) do
      def chosen_option
        options.find { |option| option["key"] == chosen_key }
      end
    end

    # An item of the equipment: its catalog entry, how many, a note ("de prières")
    Item = Data.define(:entry, :count, :note)

    def initialize(character)
      @character = character
      @game_table = character.game_table
    end

    def choices
      @choices ||= equipment_fields.filter_map do |field|
        source_option = @character.sheet[field["from"]]
        options = list_effects(field["from"], source_option).dig("starting_equipment", "options")
        next unless options

        value = @character.sheet[field["key"]].to_h
        Choice.new(field: field, source_option: source_option, options: options,
                   chosen_key: value["option"], picks: value["picks"].to_h)
      end
    end

    # Every item of the options chosen, the items of your choice once picked
    def chosen_items
      choices.flat_map { |choice| items_of(choice.chosen_option, choice.picks) }
    end

    def gold
      self.class.gold_from(fields: @game_table.character_sheet_fields, sheet: @character.sheet).to_i
    end

    # The gold of the options picked, read from the fields and the sheet alone (the rule starting_gold of
    # CharacterSheets::Calculator), nil before any option is picked
    def self.gold_from(fields:, sheet:)
      golds = fields.select { |field| field["type"] == "equipment_option" }.filter_map do |field|
        list = fields.find { |candidate| candidate["key"] == field["from"] }
        options = list&.dig("effects", sheet[field["from"]].to_s, "starting_equipment", "options").to_a
        options.find { |option| option["key"] == sheet[field["key"]].to_h["option"] }&.fetch("gold", 0)
      end
      golds.sum if golds.any?
    end

    # The items of an option, a line of your choice as its pick (none before it is picked)
    def items_of(option, picks = {})
      option.to_h["items"].to_a.each_with_index.filter_map do |line, position|
        key = line["choose"] ? picks[position.to_s] : line["key"]
        entry = catalog_items[key]
        entry && Item.new(entry: entry, count: line["count"] || 1, note: line["note"])
      end
    end

    # The items of the catalog in these groups (a musical instrument...), by name
    def items_in_groups(groups)
      catalog_items.values.select { |entry| groups.include?(entry.properties["group"]) }.sort_by(&:name)
    end

    # The items of the catalog of the table (its template's, changed by its game master: Catalogs::TableCatalog)
    def catalog_items
      @catalog_items ||= Catalogs::TableCatalog.new(@game_table).entries("item").index_by(&:key)
    end

    # nil when the value fits what its list offers: an option offered, each pick in the groups of its line
    def error_for(field, value)
      choice = choices.find { |candidate| candidate.field["key"] == field["key"] }
      option = choice&.options&.find { |candidate| candidate["key"] == value.to_h["option"] }
      return [:inclusion] unless option

      [:inclusion] unless value.to_h["picks"].to_h.all? { |position, key| pick_allowed?(option, position, key) }
    end

    # The values of the sheet without an option that is not offered any more (the class changed), and without a pick
    # that does not fit its line
    def keep_offered(sheet)
      equipment_fields.each_with_object(sheet.dup) do |field, kept_sheet|
        value = kept_sheet[field["key"]]
        next unless value

        error_for(field, value) ? kept_sheet.delete(field["key"]) : nil
      end
    end

    private

    def pick_allowed?(option, position, key)
      line = option["items"].to_a[position.to_i]
      line&.dig("choose") && items_in_groups(line["choose"]).any? { |entry| entry.key == key }
    end

    def equipment_fields
      @game_table.character_sheet_fields.select { |field| field["type"] == "equipment_option" }
    end

    def list_effects(list_key, option)
      list = @game_table.character_sheet_fields.find { |field| field["key"] == list_key }
      list&.dig("effects", option.to_s).to_h
    end
  end
end
