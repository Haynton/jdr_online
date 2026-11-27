# The spells a character may choose at the Spells step, by the groups the template declares (character_fields
# .spell_groups, decision: declared once, in the words of the game): for each group, its spells among those of its
# levels (min_level to max_level, or up to the table max_level_from of the class), as many as the table count_from of
# the class at the level of the character. The tables are read in the spellcasting effect of the option picked (the
# class), one number per level from 1 to 20 (heroic fantasy: cantrips, prepared, max_spell_level). The spells come
# from the catalog of the table (Catalogs::TableCatalog: its template's, changed by its game master).
# Beside the groups, the spells an option always prepares from a level (always_prepared_spells: the domain spells of
# the Life domain), which count in no group and cannot be chosen there.
# Known limit: the spellbook of the wizard (6 spells, some of them prepared) comes later; here every class prepares
# its spells from the list of its class
module CharacterSheets
  class CharacterSheets::SpellChoices
    # A group of the template with what the class gives at this level: its key, its label and help (the words of the
    # template), how many may be chosen, the spells offered (catalog entries, by level then by name), when they can be
    # changed in the game (changes: one of PREPARED_CHANGES), and whether it spans several levels (the page then titles
    # each level)
    Group = Data.define(:key, :label, :help, :allowed_count, :spells, :changes, :several_levels) do
      def keys
        spells.map(&:key)
      end
    end

    # When the spells of a group can be changed during the game (changes, or changes_from: a value of the class): the
    # whole list after a long rest (cleric, druid, wizard), one after a long rest (paladin, ranger), one per level
    # gained (bard, sorcerer, warlock, and the cantrips of every class; rules of 2024)
    PREPARED_CHANGES = %w[long_rest long_rest_one level_up_one].freeze

    # A group declared with a range of levels (max_level_from, or min_level under max_level)
    def self.several_levels?(declared_group)
      declared_group["max_level_from"].present? || declared_group["min_level"].to_i != declared_group["max_level"].to_i
    end

    # Whether a level of spell belongs to a declared group (the summary titles the spells chosen by their group)
    def self.covers_level?(declared_group, level)
      level >= declared_group["min_level"].to_i &&
        (declared_group["max_level_from"].present? || level <= declared_group["max_level"].to_i)
    end

    def initialize(character)
      @character = character
      @game_table = character.game_table
    end

    # The groups to choose from, those with nothing to choose left out: [] for a class without spells
    def groups
      @groups ||= @game_table.spell_groups.map { |declared_group| build_group(declared_group) }
                             .select { |group| group.allowed_count.positive? && !group.spells.empty? }
    end

    def group_of(spell_key)
      groups.find { |group| group.keys.include?(spell_key) }
    end

    # The spells its options always prepare at its level (the domain spells of the subclass)
    def always_prepared
      @always_prepared ||= CharacterSheets::AlwaysPreparedSpells.new(
        options: picked_options_with(ChoiceEffects::AlwaysPreparedSpells::KEY), level: level, spells: table_spells
      )
    end

    # The copies of the spells chosen that are still offered, at most as many per group as allowed: the spells kept
    # when the class changes (a spell of the class before goes). Those always prepared are copied again, from the
    # options picked now
    def keep_offered(chosen_spells)
      chosen_spells.reject { |spell| spell["always_prepared"] }
                   .select { |spell| group_of(spell["key"]) }
                   .group_by { |spell| group_of(spell["key"]) }
                   .flat_map { |group, spells_of_group| spells_of_group.first(group.allowed_count) } +
        always_prepared.copies
    end

    # What a character keeps of a spell: a copy, which the catalog changing never changes (decision)
    def copy_of(spell_key)
      entry = groups.flat_map(&:spells).find { |spell| spell.key == spell_key }
      entry && self.class.copy_of_entry(entry)
    end

    def self.copy_of_entry(entry)
      { "key" => entry.key, "name" => entry.name, "level" => entry.level, "description" => entry.description,
        "properties" => entry.properties }
    end

    # The level of the character (the field filled by the table, starting_level), between 1 and 20
    def level
      level_field = @game_table.character_sheet_fields.find { |field| field["from_table"] == "starting_level" }
      value = level_field && @character.sheet[level_field["key"]]
      (value || @game_table.starting_level).to_i.clamp(1, 20)
    end

    # The spellcasting effect of the option picked (the class), {} for a class without spells: its tables are also
    # read by CharacterSheets::SpellSlots
    def spellcasting
      picked_spellcasting&.last || {}
    end

    private

    # The spells of the catalog of the table (its template's, changed by its game master: Catalogs::TableCatalog)
    def table_spells
      Catalogs::TableCatalog.new(@game_table).entries("spell")
    end

    # Those of the class, without those always prepared
    def catalog_spells
      return CatalogEntry.none unless class_option

      table_spells.for_class(class_option).where.not(key: always_prepared.keys).by_level_and_name
    end

    def build_group(declared_group)
      spell_levels = declared_group["min_level"].to_i..highest_level_of(declared_group)
      Group.new(key: declared_group["key"], label: declared_group["label"], help: declared_group["help"],
                allowed_count: table_at_level(declared_group["count_from"]),
                spells: catalog_spells.of_level(spell_levels.to_a).to_a,
                changes: declared_group["changes"] || spellcasting[declared_group["changes_from"]],
                several_levels: self.class.several_levels?(declared_group))
    end

    def highest_level_of(declared_group)
      table_key = declared_group["max_level_from"]
      table_key ? table_at_level(table_key) : declared_group["max_level"].to_i
    end

    # The number of a table of the class at the level of the character (0 without the table)
    def table_at_level(table_key)
      spellcasting.dig(table_key, level - 1).to_i
    end

    # The option picked with a spellcasting effect (the class: "Magicien")
    def class_option
      picked_spellcasting&.first
    end

    def picked_spellcasting
      @picked_spellcasting ||= picked_options_with(ChoiceEffects::Spellcasting::KEY).first
    end

    # [option, value of the effect] for each option picked that has this effect
    # Also the options picked in the groups of choices of the class (the land of the circle and its spells)
    def picked_options_with(effect_key)
      from_lists = @game_table.character_sheet_fields.filter_map do |field|
        option = @character.sheet[field["key"]]
        value = field.dig("effects", option.to_s, effect_key)
        [option, value] if value
      end
      from_lists + class_choice_options_with(effect_key)
    end

    def class_choice_options_with(effect_key)
      @character.class_choice_groups(level: level).picked_effects.filter_map do |label, effects|
        [label, effects[effect_key]] if effects[effect_key]
      end
    end
  end
end
