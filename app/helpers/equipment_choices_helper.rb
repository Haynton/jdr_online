# The starting equipment on the Equipment step (StartingEquipment): one block per list (the class, the background),
# a switch "Prendre les objets | Prendre 150 pièces d'or" drawn like the theme selector, then the items of the option
# chosen, one line per item (decision: the packs are opened in the template), an item of your choice as a list in its
# line
module EquipmentChoicesHelper
  SCOPE = "game_tables.character_steps.equipment_choices".freeze
  # The switch: the field background, the option chosen as a surface pill (shared/_theme_choice), the whole option
  # clickable (its label holds its radio). Without JavaScript too. No ring (decision): an option is always chosen,
  # the items by default (equipment_option_checked?), so the pill always draws the switch
  SWITCH_CLASSES = "inline-flex max-w-full flex-wrap gap-1 rounded-lg bg-field p-1".freeze
  SWITCH_OPTION_CLASSES = %w[
    inline-flex h-8 cursor-pointer items-center rounded-md px-3 text-sm text-ink transition-colors hover:bg-surface/60
    has-checked:bg-surface has-checked:font-semibold has-checked:shadow-sm
    has-focus-visible:outline-2 has-focus-visible:outline-offset-2 has-focus-visible:outline-focus-ring
  ].join(" ").freeze
  # The items of an option show once it is chosen, read from the radios of the block (group on the fieldset): written
  # in full for each letter, Tailwind builds no class put together
  OPTION_PANEL_CLASSES = {
    "a" => "hidden group-has-[input[type=radio][value=a]:checked]:block",
    "b" => "hidden group-has-[input[type=radio][value=b]:checked]:block",
    "c" => "hidden group-has-[input[type=radio][value=c]:checked]:block"
  }.freeze
  # One line per item: its name, its category, damage or armour class, its weight in columns when its block is 576 px
  # wide (container query: the blocks sit in two columns from 1024 px); narrower, the name on its line, the rest
  # together on a second one
  ITEM_LINE_CLASSES = "flex flex-wrap items-baseline gap-x-3 py-2 text-sm " \
                      "@xl:grid @xl:grid-cols-[minmax(0,1fr)_7rem_8rem_4rem] @xl:items-center @xl:gap-x-4".freeze

  # "Classe · Rôdeur"
  def equipment_source_title(choice, fields)
    list = fields.find { |field| field["key"] == choice.field["from"] }
    "#{list&.dig('label')} · #{choice.source_option}"
  end

  # "Prendre les objets" (or "Objets A", "Objets B" when there are several), "Prendre 150 pièces d'or"
  def equipment_option_label(choice, option)
    return t("#{SCOPE}.take_gold", count: option["gold"].to_i) if option["items"].blank?

    several = choice.options.count { |candidate| candidate["items"].present? } > 1
    several ? t("#{SCOPE}.items_option", letter: option["key"].upcase) : t("#{SCOPE}.take_items")
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

  # The option saved, or before any choice the first one with items (decision: the items by default); it is saved
  # with the step
  def equipment_option_checked?(choice, option)
    return equipment_option_chosen?(choice, option) if choice.chosen_key

    option == choice.options.find { |candidate| candidate["items"].present? }
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

  # The weight of the line (5 kg for 10 torches), in the unit of the template, nothing for an item of no weight
  def equipment_item_weight(item)
    weight = item.entry.properties["weight"].to_f * item.count
    return if weight.zero?

    t("#{SCOPE}.weight", value: number_with_precision(weight, precision: 2, strip_insignificant_zeros: true))
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
    entry && StartingEquipment::Item.new(entry: entry, count: line["count"] || 1, note: line["note"])
  end
end
