# The starting equipment on the Equipment step (CharacterSheets::StartingEquipment): one block per list (the class,
# the background), its options as tabs (EquipmentOptionTabsHelper), then the items of the option
# chosen, one line per item (decision: the packs are opened in the template), an item of your choice as a list in its
# line
module CharacterSheets
  module CharacterSheets::EquipmentChoicesHelper
    SCOPE = "game_tables.character_steps.equipment_choices".freeze
    # The items of an option show once it is chosen, read from the radios of the block (group on the fieldset): written
    # in full for each letter, Tailwind builds no class put together
    OPTION_PANEL_CLASSES = {
      "a" => "hidden group-has-[input[type=radio][value=a]:checked]:block",
      "b" => "hidden group-has-[input[type=radio][value=b]:checked]:block",
      "c" => "hidden group-has-[input[type=radio][value=c]:checked]:block"
    }.freeze
    # One line per item, 36 px: a small diamond, its name, its damage, armour class or category (from 640 px: on a
    # phone it took the room of the name), its weight
    ITEM_LINE_CLASSES = %w[
      grid h-9 grid-cols-[10px_minmax(0,1fr)_3.5rem] items-center gap-x-3 border-b border-line px-3 text-sm
      last:border-b-0 sm:grid-cols-[10px_minmax(0,1fr)_minmax(0,auto)_3.5rem]
    ].join(" ").freeze
    # An item to choose: the diamond, what to choose, its list on the right
    CHOOSE_LINE_CLASSES = %w[
      grid h-10 grid-cols-[10px_minmax(0,1fr)_auto] items-center gap-x-3 border-b border-line px-3 text-sm
      last:border-b-0
    ].join(" ").freeze
    # The list of an item to choose, read as the detail of its line: no field, its value in gold, a chevron after it.
    # Its focus a light background, not the outline (Chrome draws the outline of the keyboard after a click on a list);
    # after a pick with the pointer the list lets go of its focus (pointer_pick_controller.js): the background stays
    # for the keyboard only
    PICK_CLASSES = %w[
      max-w-48 cursor-pointer appearance-none truncate rounded-md border-0 bg-transparent py-1 pr-5 pl-2 text-right
      text-sm font-semibold text-brass hover:bg-surface focus:bg-surface-raised focus:outline-none
    ].join(" ").freeze
    ITEM_MARKER_CLASSES = "size-[7px] justify-self-center rotate-45 rounded-[1px] bg-brass".freeze

    # "Classe · Rôdeur"
    def equipment_source_title(choice, fields)
      list = fields.find { |field| field["key"] == choice.field["from"] }
      "#{list&.dig('label')} · #{choice.source_option}"
    end

    def equipment_option_input_name(choice, part)
      "character[sheet][#{choice.field['key']}][#{part}]"
    end

    def equipment_option_id(choice, option)
      "character_sheet_#{choice.field['key']}_#{option['key']}"
    end

    def equipment_option_chosen?(choice, option)
      choice.chosen_key == option["key"]
    end

    # The option saved, or before any choice the first one with items (decision: the items by default), the first one
    # when the table keeps only gold; it is saved with the step
    def equipment_option_checked?(choice, option)
      return equipment_option_chosen?(choice, option) if choice.chosen_key

      option == choice.default_option
    end

    def equipment_option_panel_classes(option)
      OPTION_PANEL_CLASSES.fetch(option["key"])
    end

    # "10 × Torche", "Livre de prières"
    def equipment_item_text(item)
      name = [item.entry.name, item.note].compact.join(" ")
      item.count > 1 ? t("#{SCOPE}.item_count", count: item.count, name: name) : name
    end

    # Its damage ("1d8 perforants") or its armour class ("CA 12 + Dex", "CA +2")
    def equipment_item_detail(item)
      properties = item.entry.properties
      return properties["damage"] if properties["damage"]

      t("#{SCOPE}.armor_class", value: properties["armor_class"]) if properties["armor_class"]
    end

    # A line of the inventory of a complete character, written like a line of the starting equipment ("10 × Torche")
    def inventory_item_text(item)
      item.quantity > 1 ? t("#{SCOPE}.item_count", count: item.quantity, name: item.name) : item.name
    end

    def inventory_item_detail(item)
      return item.properties["damage"] if item.properties["damage"]

      t("#{SCOPE}.armor_class", value: item.properties["armor_class"]) if item.properties["armor_class"]
    end

    # The weight of the line (5 kg for 10 torches), in the unit of the template, nothing for an item of no weight
    def equipment_item_weight(item)
      weight = item.entry.properties["weight"].to_f * item.count
      return if weight.zero?

      t("#{SCOPE}.weight", value: number_with_precision(weight, precision: 2, strip_insignificant_zeros: true))
    end

    # The gold the options chosen give together (the options checked when the page opens; the page counts again)
    def equipment_starting_gold(choices)
      choices.sum do |choice|
        checked = choice.options.find { |option| equipment_option_checked?(choice, option) }
        checked.to_h["gold"].to_i
      end
    end

    # "+ 7 pièces d'or" after the items of an option
    def equipment_gold_text(option)
      gold = option["gold"].to_i
      t("#{SCOPE}.plus_gold", count: gold) unless gold.zero?
    end

    # "Instrument de musique", "Outils d'artisan ou instrument de musique"
    def equipment_choose_label(groups)
      labels = groups.map { |group| t("#{SCOPE}.groups.#{group}") }
      labels.to_sentence(two_words_connector: t("#{SCOPE}.or"), last_word_connector: t("#{SCOPE}.or"))
    end

    # The items to choose from, by group when there are several (optgroups: the monk)
    def equipment_pick_options(starting_equipment, groups, picked_key)
      if groups.one?
        return options_from_collection_for_select(starting_equipment.items_in_groups(groups), :key, :name, picked_key)
      end

      grouped = groups.map do |group|
        items = starting_equipment.items_in_groups([group]).map { |entry| [entry.name, entry.key] }
        [t("#{SCOPE}.groups.#{group}"), items]
      end
      grouped_options_for_select(grouped, picked_key)
    end

    def equipment_line_item(line, starting_equipment)
      entry = starting_equipment.catalog_items[line["key"]]
      entry && CharacterSheets::StartingEquipment::Item.new(entry: entry, count: line["count"] || 1, note: line["note"])
    end
  end
end
