# The Details step (character_sheets/sections/_split): its fields in three bands, the alignment picked on a grid of two
# axes (character_sheets/fields/_grid_choice, grid_choice_controller.js), the long texts with the questions of their
# help
module CharacterSheets
  module DetailsHelper
    # The look of the theme selector: one value chosen per axis, the whole value clickable
    GRID_OPTION_CLASSES = %w[
      inline-flex min-h-8 min-w-0 flex-1 cursor-pointer items-center justify-center rounded-md px-2 py-1
      text-center text-[13px] leading-tight text-ink transition-colors hover:bg-surface/60 has-checked:bg-surface
      has-checked:font-semibold has-checked:shadow-sm has-focus-visible:outline-2 has-focus-visible:outline-offset-2
      has-focus-visible:outline-focus-ring
    ].join(" ").freeze
    # A language to pick, at the look of the filter pills (FILTER_PILL_CLASSES): a real box under its label
    PICK_PILL_CLASSES = %w[
      inline-flex h-8 shrink-0 cursor-pointer items-center rounded-full border border-line px-3 text-[13px]
      font-medium text-ink transition-colors hover:bg-surface-raised
      has-checked:border-primary-soft-ink/50 has-checked:bg-primary-soft has-checked:text-primary-soft-ink
      has-focus-visible:outline-2 has-focus-visible:outline-offset-2 has-focus-visible:outline-focus-ring
    ].join(" ").freeze
    # A language always known (the Common tongue): ticked, never clickable
    GRANTED_PILL_CLASSES = "inline-flex h-8 shrink-0 items-center gap-1.5 rounded-full bg-field px-3 text-[13px] " \
                           "font-medium text-ink".freeze
    # The long texts kept low (decision: the three side by side fit in the screen with the bands above)
    GUIDED_TEXT_AREA_CLASSES = "h-32 min-h-24".freeze

    # { choices: the lists and picks, shorts: the short texts, texts: the long texts }, in the order of the template
    def details_bands(fields)
      bands = fields.group_by do |field|
        next :texts if sheet_flow_group(field) == :texts
        next :shorts if field["type"] == "text" && field["short"]

        :choices
      end
      { choices: [], shorts: [], texts: [] }.merge(bands)
    end

    # [row, column] of the option picked in its grid, nil each while nothing is picked
    def grid_choice_position(grid, value)
      grid["options"].each_with_index do |row, row_index|
        column_index = row.index(value)
        return [row_index, column_index] if column_index
      end
      [nil, nil]
    end

    # The radio of a value of an axis, not sent under character: grid_choice_controller.js writes the option in the list
    def grid_axis_radio(field, axis, index, chosen_index)
      radio_button_tag "grid_choice[#{field['key']}][#{axis}]", index, index == chosen_index,
                       class: "sr-only", id: nil,
                       data: { grid_choice_target: "radio", axis: axis, action: "grid-choice#pick" }
    end

    def grid_axis_id(field, axis)
      "#{sheet_field_id(field)}_#{axis}"
    end

    # A long text under its label and its questions, which screen readers read with it
    def sheet_guided_text_area(character, field)
      options = sheet_control_options(character, field)
      described_by = [("#{sheet_field_id(field)}_hint" if field["help"]), options.dig(:aria, :describedby)].compact
      options[:aria] = options[:aria].merge(describedby: described_by.join(" ").presence).compact
      text_area_tag(sheet_field_name(field), sheet_field_value(character, field),
                    options.merge(class: "#{FieldsHelper::TEXTAREA_CLASSES} #{GUIDED_TEXT_AREA_CLASSES}", rows: 5))
    end
  end
end
