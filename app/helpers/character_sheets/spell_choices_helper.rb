# The spells to choose at the Spells step (CharacterSheets::SpellChoices): one row per spell, its count per group, the
# search. The browser keeps the counts and the search up to date (spell_choices_controller.js); the server decides
# (CharacterSpellsValidator)
module CharacterSheets
  module CharacterSheets::SpellChoicesHelper
    # A spell chosen keeps the gold outline of a card chosen (choice_tile_classes)
    # min-w-0: on a phone, a card holds in its column instead of stretching to its content (it widened the page)
    SPELL_ROW_CLASSES = "flex min-w-0 flex-col rounded-lg border border-line bg-surface px-3 py-2.5 " \
                        "has-checked:border-brass has-checked:ring-1 has-checked:ring-brass " \
                        "has-checked:ring-inset".freeze
    # 18 px plus its border: as high as the name beside it (20 px), the cards keep the same height
    SPELL_TAG_CLASSES = "rounded-full border border-line px-2 text-[11px] leading-[18px] font-medium text-muted".freeze
    SCOPE = "game_tables.character_steps.spell_choices".freeze
    # Kept for the controller, which writes the counts in the browser
    CHOSEN_PLACEHOLDER = "%{chosen}".freeze # rubocop:disable Style/FormatStringToken
    ALLOWED_PLACEHOLDER = "%{allowed}".freeze # rubocop:disable Style/FormatStringToken

    # "Évocation · Action · 36 mètres · Instantanée". A reaction keeps only its first words ("Réaction"): its trigger
    # is in the details (spell_casting_trigger), the card keeps its height
    def spell_summary_line(spell)
      casting_time = spell.properties["casting_time"].to_s.split(",").first
      range, duration = spell.properties.values_at("range", "duration")
      [spell.properties["school"], casting_time, range, duration].compact_blank.join(" · ")
    end

    # "Réaction, quand un jet d'attaque vous touche...": the whole casting time when it says more than the card
    def spell_casting_trigger(spell)
      casting_time = spell.properties["casting_time"].to_s
      casting_time if casting_time.include?(",")
    end

    # Concentration, Ritual: what changes how the spell is cast
    def spell_tags(spell)
      %w[concentration ritual].select { |property| spell.properties[property] }
                              .map { |property| t("#{SCOPE}.#{property}") }
    end

    # "V, S, M (une pincée de suie et de sel)"
    def spell_components(spell)
      components = spell.properties["components"].to_a.join(", ")
      material = spell.properties["material"]
      material ? "#{components} (#{material})" : components
    end

    # What the filters read: its level, its school, concentration and ritual (several, separated by spaces)
    def spell_card_data(spell)
      castings = %w[concentration ritual].select { |property| spell.properties[property] }
      { spell_choices_target: "spell", name: spell_search_name(spell), level: spell.level,
        school: spell.properties["school"], casting: castings.join(" ") }
    end

    # What the group is (its help, in the words of the template), then when its spells can be changed during the game
    # (its changes: a cantrip per level gained; the prepared spells after a long rest or per level, by class)
    def spell_group_hint(group)
      [group.help, (t("#{SCOPE}.changes.#{group.changes}") if group.changes)].compact_blank.join(" ")
    end

    # The pills of the filters, by group: levels and schools of the spells offered, concentration and ritual, then the
    # spells chosen. A level or a school alone, shared by every spell, would filter nothing: its group is left out.
    # [[:level, [["0", "Sorts mineurs"], ["1", "Niveau 1"]]], [:school, [...]], ...]
    def spell_filter_groups(groups)
      spells = groups.flat_map(&:spells)
      sorting_groups = { level: spell_level_pills(groups), school: spell_school_pills(spells) }
      sorting_groups.select { |_group, pills| pills.size > 1 }
                    .merge(casting: spell_casting_pills(spells), chosen: [["chosen", t("#{SCOPE}.chosen_only")]])
                    .reject { |_group, pills| pills.empty? }.to_a
    end

    def spell_filter_label(group)
      t("#{SCOPE}.filter_#{group}")
    end

    def spell_box_id(spell)
      "character_spell_#{spell.key.underscore}"
    end

    # The name without accents nor capitals, which the search compares with what is typed
    def spell_search_name(spell)
      I18n.transliterate(spell.name).downcase
    end

    def spell_chosen?(character, spell)
      character.spells.any? { |chosen| chosen["key"] == spell.key }
    end

    # "2 sur 3 choisis", and whether it is too many (then in red, data-invalid)
    def spell_group_status(character, group)
      t("#{SCOPE}.chosen", chosen: spell_chosen_count(character, group), allowed: group.allowed_count)
    end

    def spell_group_over?(character, group)
      spell_chosen_count(character, group) > group.allowed_count
    end

    def spell_group_data(group)
      { spell_choices_target: "group", allowed: group.allowed_count,
        template: t("#{SCOPE}.chosen", chosen: CHOSEN_PLACEHOLDER, allowed: ALLOWED_PLACEHOLDER) }
    end

    # "Donnés par Domaine de la Vie : ils ne comptent pas dans vos sorts à choisir."
    def always_prepared_spells_hint(always_prepared)
      t("#{SCOPE}.always_prepared_hint", sources: always_prepared.sources.to_sentence)
    end

    # The prepared spells by level: [[1, [...]], [2, [...]]]
    def spells_by_level(group)
      group.spells.group_by(&:level).sort
    end

    private

    # A level alone in its group is named by the group ("Sorts mineurs"), the others by their number ("Niveau 1")
    def spell_level_pills(groups)
      groups.flat_map do |group|
        group.spells.map(&:level).uniq.sort.map { |level| [level.to_s, spell_level_title(group, level)] }
      end
    end

    def spell_school_pills(spells)
      schools = spells.map { |spell| spell.properties["school"] }.uniq
      schools.sort_by { |school| I18n.transliterate(school) }.map { |school| [school, school] }
    end

    def spell_casting_pills(spells)
      %w[concentration ritual].select { |property| spells.any? { |spell| spell.properties[property] } }
                              .map { |property| [property, t("#{SCOPE}.#{property}")] }
    end

    def spell_level_title(group, level)
      group.several_levels ? t("#{SCOPE}.level", level: level) : group.label
    end

    def spell_chosen_count(character, group)
      character.spells.count { |spell| group.keys.include?(spell["key"]) }
    end
  end
end
