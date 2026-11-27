# The saving throws and the skills of the creation as a character sheet (decision, prototype "Création façon jeu"): one
# line each, a small diamond, the bonus, the name and the ability. The state of each line:
# - given: an option or a feat gives it (its source written beside the name), the diamond filled in ink;
# - choice: an option of the template may offer it: dashed while the options picked offer it (data-offered, set here
#   and kept up to date by character_sheet_controller.js when the option is on the same page), gold once picked, faded
#   when not offered and the table limits the skills (data-off, skill_rows_controller.js);
# - free: nothing in the template picks it (a game without classes), the player ticks it;
# - off: only an option gives it (a saving throw of a class) and the table keeps the given choices: never ticked here.
# The box is the field the step always sent, hidden in the line: the server checks it as before
module CharacterSheets
  module SkillRowsHelper
    SKILL_ROW_CLASSES = %w[
      grid h-10 w-full grid-cols-[10px_2rem_minmax(0,1fr)_auto] items-center gap-2.5 rounded-lg border
      border-transparent px-3 text-sm text-ink transition-colors peer-focus-visible:outline-2
      peer-focus-visible:outline-offset-2 peer-focus-visible:outline-focus-ring
    ].join(" ").freeze

    # A line picked (its box ticked) in the tonal gold of a card picked; written in full by state
    SKILL_ROW_STATE_CLASSES = {
      given: "cursor-default font-semibold",
      choice: %w[
        cursor-pointer hover:bg-surface group-data-offered/skill:border-dashed
        group-data-offered/skill:border-field-line group-data-offered/skill:hover:border-brass
        group-has-[input[value='1']:checked]/skill:border-solid
        group-has-[input[value='1']:checked]/skill:border-chosen-line
        group-has-[input[value='1']:checked]/skill:bg-primary-soft
        group-has-[input[value='1']:checked]/skill:text-primary-soft-ink
        group-data-off/skill:cursor-default group-data-off/skill:text-muted group-data-off/skill:hover:bg-transparent
        group-data-full/skill:cursor-not-allowed group-data-full/skill:opacity-45
      ].join(" "),
      free: %w[
        cursor-pointer hover:bg-surface group-has-[input[value='1']:checked]/skill:border-chosen-line
        group-has-[input[value='1']:checked]/skill:bg-primary-soft
        group-has-[input[value='1']:checked]/skill:text-primary-soft-ink
      ].join(" "),
      off: "cursor-default text-muted"
    }.freeze

    SKILL_MARKER_CLASSES = {
      given: "border-ink bg-ink",
      choice: %w[
        border-field-line group-data-offered/skill:border-brass group-has-[input[value='1']:checked]/skill:border-brass
        group-has-[input[value='1']:checked]/skill:bg-brass
      ].join(" "),
      free: %w[
        border-field-line group-has-[input[value='1']:checked]/skill:border-brass
        group-has-[input[value='1']:checked]/skill:bg-brass
      ].join(" "),
      off: "border-field-line"
    }.freeze

    # The diamonds of the legend under the skills: to pick, picked, given
    SKILL_LEGEND_MARKER_CLASSES = {
      offered: "border-brass", picked: "border-brass bg-brass", given: "border-ink bg-ink"
    }.freeze

    def skill_row_state(character, field)
      return :given if sheet_given_by(character, field)

      choices = character.skill_choices
      return :choice if choices.skill_keys.include?(field["key"])
      return :free unless choices.givable_keys.include?(field["key"])

      character.game_table.players_change_given_choices ? :free : :off
    end

    # Offered by the options picked (saved): the controller keeps it up to date when the option is on the same page
    def skill_row_offered?(character, field)
      character.skill_choices.offered_keys.include?(field["key"])
    end

    # Not offered while the table limits the skills: faded and its box disabled
    def skill_row_off?(character, field, state)
      state == :choice && character.game_table.limit_skill_choices && !skill_row_offered?(character, field)
    end

    # Given and kept by the table: ticked for good; not for this character: never
    def skill_row_availability(character, field, state)
      return :unavailable if state == :off || skill_row_off?(character, field, state)
      return :locked if state == :given && character.given_locked?(field["key"])

      :open
    end

    def skill_row_classes(state)
      "#{SKILL_ROW_CLASSES} #{SKILL_ROW_STATE_CLASSES.fetch(state)}"
    end

    def skill_marker_classes(state)
      "size-2.5 justify-self-center rotate-45 rounded-[2px] border #{SKILL_MARKER_CLASSES.fetch(state)}"
    end

    def skill_legend_marker_classes(marker)
      "size-2.5 rotate-45 rounded-[2px] border #{SKILL_LEGEND_MARKER_CLASSES.fetch(marker)}"
    end

    # The lines run down a column, then the next one (the order of the template, alphabetical): half of them per column
    def skill_rows_style(fields)
      "--skill-rows: #{(fields.size / 2.0).ceil}"
    end

    # What the skills controller needs: whether the table limits them (then the others fade)
    def skill_rows_data(character)
      { controller: "skill-rows", action: "change->skill-rows#refresh",
        skill_rows_limited_value: character.game_table.limit_skill_choices.present? }
    end
  end
end
