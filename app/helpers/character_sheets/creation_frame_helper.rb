# The frame of the creation of a character (layouts/character_creation), a game screen on the whole screen (decision,
# prototype "Création façon jeu"): the band of the hero on top (game_tables/character_steps/_hero), the rail of the
# steps on the left (_rail), the step in the middle under a centered title (_title), its buttons in a bar at the bottom
# (_actions). One shape for what is picked, the card (CARD_CLASSES): a border all around, corners of 10 px, no
# background at rest; picked, a thin border chosen-line and the tonal gold background, no shadow (decision)
module CharacterSheets
  module CreationFrameHelper
    CARD_CLASSES = %w[
      rounded-[10px] border border-line transition-colors hover:border-field-line hover:bg-surface
      aria-pressed:border-chosen-line aria-pressed:bg-primary-soft aria-pressed:text-primary-soft-ink
    ].join(" ").freeze

    # A step of the rail: a diamond with rounded corners and its number, the current one larger and filled
    RAIL_DIAMOND_CLASSES = {
      done: "size-[22px] border-brass bg-primary-soft text-primary-soft-ink",
      current: "size-[26px] border-brass bg-brass text-page ring-4 ring-brass/20",
      upcoming: "size-[22px] border-field-line bg-page text-muted"
    }.freeze

    # The sections of a step side by side when it holds only saving throws and skills (decision, prototype "Création
    # façon jeu"): the saving throws in a narrow column on the left, the skills on the right, as on a character sheet
    def creation_sections_classes(sections)
      return "contents" unless sheet_side_by_side?(sections)

      "mx-auto grid w-full max-w-5xl gap-10 lg:grid-cols-[20rem_minmax(0,1fr)]"
    end

    def sheet_side_by_side?(sections)
      sections.size == 2 && sections.all? { |_section, fields| sheet_section_layout(fields) == :rows }
    end

    def creation_card_classes(extra = nil)
      [CARD_CLASSES, extra].compact.join(" ")
    end

    def rail_diamond_classes(state)
      RAIL_DIAMOND_CLASSES.fetch(state)
    end

    # The line under the name in the band: the options picked that shape the character (class, background, species),
    # or, before any, the table it is made for
    def creation_hero_line(character)
      choices = character_card_choices(character)
      choices.presence || t("game_tables.character_steps.frame.table", name: character.game_table.name)
    end

    # The numbers of the character in the band, [[short label, text]]: the boxes of the steps with nothing to fill in
    # (the combat: hit points, armour class, initiative...), worked out by the template. "—" until what they read is
    # picked. They change with the choices
    def creation_hero_numbers(character, computed)
      worked_out_steps = character.creation_steps.summary_blocks.select(&:summary_only)
      fields = worked_out_steps.flat_map(&:fields).select { |field| summary_group(field) == :boxes }
      fields.map { |field| [field["abbreviation"] || field["label"], summary_value(character, field, computed)] }
    end

    # The step after this one, said beside Continue
    def creation_next_step_label(character, step)
      next_step = character.creation_steps.after(step)
      next_step && t("game_tables.character_steps.frame.next", step: character_step_label(next_step))
    end
  end
end
