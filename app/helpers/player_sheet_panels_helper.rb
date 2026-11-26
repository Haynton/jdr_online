# The panels of a player's sheet in the game room (decision of 26 November: every piece of information of the sheet
# has its panel, the whole sheet is only opened to change it): « Ma fiche » (the values of a fight, the abilities),
# « Compétences » (every bonus row), « Inventaire », « Sorts » and « Détails » (everything else the sheet shows)
module PlayerSheetPanelsHelper
  # The values a player looks at in a fight, beside the armour class of « Ma fiche ». First version, written for D&D
  # like the armour class (CombatStrip): the template will declare them (decision: the room keeps its shape, the
  # template decides what fills it)
  QUICK_STAT_FIELD_KEYS = %w[initiative speed proficiency_bonus hit_dice].freeze
  # Those of a caster, at the top of the panel « Sorts » with the spell slots (decision of 26 November: they are looked
  # at while casting a spell)
  SPELL_STAT_FIELD_KEYS = %w[spell_save_dc spell_attack_bonus].freeze
  # The armour class of « Ma fiche » (CombatStrip::Fighter#armor_class reads it)
  ARMOR_CLASS_KEY = "armor_class".freeze
  # « −1 » beside an item of the inventory: a small button with its border, the text says what it does (decision: a
  # bare − without a border read as an empty value). line on surface; muted on surface 9.25 and 4.6 or more
  TAKE_ONE_BUTTON_CLASSES = %w[
    inline-flex h-7 min-w-10 cursor-pointer items-center justify-center rounded-md border border-line px-2 text-xs
    font-semibold text-muted tabular-nums transition-colors hover:border-field-line hover:bg-surface-raised
    hover:text-ink focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus-ring
  ].join(" ").freeze
  # The groups of the summary sheet « Détails » leaves out: the abilities (« Ma fiche »), the bonus rows
  # (« Compétences »), and the long texts (appearance, story: Anthony's request, too long for a narrow panel and of
  # little use during the game; they are read and changed in « Modifier ma fiche »)
  GROUPS_LEFT_OUT_OF_DETAILS = %i[tiles rows texts].freeze

  # Each with its short label (the abbreviation of the template, else its label), its label and its value; none for a
  # value the character has not (the spell save DC of a class without spells)
  def own_quick_stats(character, computed, keys: QUICK_STAT_FIELD_KEYS)
    character.sheet_fields.select { |field| keys.include?(field["key"]) }.filter_map do |field|
      value = own_stat_value(character, field, computed)
      next if value.blank? || value == "—"

      { short_label: field["abbreviation"] || field["label"], label: field["label"], value: value }
    end
  end

  # The bonus fields of a sheet (saving throws, skills), by the section of the template: the panel « Compétences »
  def own_bonus_sections(character)
    character.sheet_fields.select { |field| field["type"] == "bonus" }.group_by { |field| field["section"] }
  end

  # The section with one bonus per ability (the saving throws) also goes into the tiles of the abilities: its label
  # and its fields by ability key, nil when the template has none
  def own_tile_bonus_section(bonus_sections, ability_fields)
    ability_keys = ability_fields.pluck("key").sort
    section, fields = bonus_sections.find { |_, candidates| candidates.pluck("based_on").sort == ability_keys }
    [section, fields.index_by { |field| field["based_on"] }] if section
  end

  # A bonus field ticked on the sheet: the character is proficient in it
  def own_ticked?(character, field)
    character.sheet.to_h[field["key"]] == true
  end

  # The values of the game kept with the inventory (the gold): those of the step that chooses the equipment, as on
  # the summary sheet (summary_play_fields); none for a template without that step
  def own_inventory_play_fields(character)
    step = character.creation_steps.summary_blocks.find do |candidate|
      candidate.behaviors.any?(CreationStepBehaviors::ChoosesEquipment)
    end
    step ? summary_play_fields(character, step) : []
  end

  # The « −1 » of a line of the inventory takes one away without a question; the last one removes the line, asked first
  # in the confirmation window (in red)
  def own_inventory_removal_form_data(item)
    return {} if item.quantity > 1

    { turbo_confirm: t("game_rooms.panels.inventory.remove_confirm", name: item.name),
      confirm_button: t("game_rooms.panels.inventory.remove"), confirm_variant: "danger" }
  end

  # A value kept with the inventory that an amount may be taken out of (the gold pieces spent): a number, while the
  # character has some (GameTables::InventoryValuesController checks the same)
  def own_removable_value?(character, field)
    field["type"] == "number" && character.sheet.to_h[field["key"]].to_i.positive?
  end

  # « Changer mes sorts »: a character whose class has spells to choose (GameTables::SpellChoicesController checks
  # the same)
  def own_spells_changeable?(character)
    character.complete? && character.spell_choices.groups.any?
  end

  # Everything else the summary sheet shows, by section, in the groups of the summary sheet (the panel « Détails »):
  # nothing short of the sheet is missing from the panels, whatever the template (the long texts are in « Modifier ma
  # fiche », GROUPS_LEFT_OUT_OF_DETAILS). Left out, shown by another panel: the
  # choices under the name (lists whose options have effects), the values of « Ma fiche » and « Sorts » and what fills
  # them (initial_from: the worked out armour class and hit points), the abilities, the bonus rows; the equipment and
  # the spells (behaviours of their steps, not fields)
  def own_detail_sections(character)
    shown_elsewhere = own_keys_shown_elsewhere(character)
    fields = own_sheet_fields_shown(character).reject do |field|
      shown_elsewhere.include?(field["key"]) || field["effects"].present?
    end
    fields.group_by { |field| field["section"] }
          .reject { |_, section_fields| summary_section_empty?(character, section_fields) }
          .transform_values { |section_fields| own_detail_groups(character, section_fields) }
          .reject { |_, groups| groups.empty? }
  end

  private

  def own_stat_value(character, field, computed)
    return format_computed_value(computed[:values][field["key"]]) unless FieldTypes.of(field).stored?

    value = character.sheet.to_h[field["key"]]
    FieldTypes.of(field).summary_text(value, field) unless value.nil?
  end

  # The fields of the summary sheet; the values the table gives (the level) with the first section, as in the
  # header of the sheet (summary_table_fields)
  def own_sheet_fields_shown(character)
    step_fields = character.creation_steps.summary_blocks.flat_map(&:fields)
    first_section = step_fields.first&.dig("section")
    step_fields + summary_table_fields(character).map { |field| field.merge("section" => first_section) }
  end

  def own_keys_shown_elsewhere(character)
    gauge_field = character.sheet_fields.find { |field| field["receives_damage"] }
    keys = QUICK_STAT_FIELD_KEYS + SPELL_STAT_FIELD_KEYS + [ARMOR_CLASS_KEY, gauge_field&.dig("key")].compact
    filling_keys = character.sheet_fields.select { |field| keys.include?(field["key"]) }
                            .filter_map { |field| field["initial_from"] }
    keys + filling_keys
  end

  def own_detail_groups(character, fields)
    summary_groups(fields, character.sheet).to_h.except(*GROUPS_LEFT_OUT_OF_DETAILS)
  end
end
