# The steps of the creation of a table and the choices of its first step (cover, sheet template)
module GameTableCreationHelper
  # A choice drawn as a tile: its radio button is hidden from sight but still focused and read (sr-only, peer),
  # the tile right after it shows the state: gold outline when chosen, focus outline from the keyboard,
  # red outline once refused. The chosen tile keeps its gold outline under the mouse and after a refusal
  # (hover and aria-invalid come later in the CSS: without the last two classes, they won)
  CHOICE_TILE_CLASSES = %w[
    block h-full cursor-pointer overflow-hidden rounded-xl bg-surface ring-1 ring-line transition-shadow
    hover:ring-field-line peer-checked:ring-2 peer-checked:ring-brass
    peer-focus-visible:outline-2 peer-focus-visible:outline-offset-2 peer-focus-visible:outline-focus-ring
    peer-aria-invalid:ring-error-ink
    peer-checked:hover:ring-brass peer-checked:peer-aria-invalid:ring-brass
  ].join(" ").freeze

  # The check in the corner of the chosen tile: a sibling of the radio button too, shown once it is checked
  CHOICE_CHECK_CLASSES = %w[
    pointer-events-none absolute top-2 right-2 hidden size-6 items-center justify-center rounded-full
    bg-brass text-page peer-checked:flex
  ].join(" ").freeze

  # Tonal colors only: a filled plaque is kept for buttons
  STEP_MARKER_CLASSES = {
    done: "bg-primary-soft text-primary-soft-ink",
    current: "bg-primary-soft text-primary-soft-ink ring-2 ring-primary-soft-ink",
    upcoming: "border border-field-line text-muted",
    coming_soon: "border border-dashed border-field-line text-muted"
  }.freeze

  # A page of the creation: the band of the steps across the whole width, then the page content.
  # The block is captured here, while the page is still the current template, so that its short translation
  # keys (t(".title")) are looked up for the page and not for the partial (same as auth_card)
  def creation_page(current_step:, &)
    content = capture(&)
    content_for(:full_width_page) { render "game_tables/creation_page", current_step: current_step, content: content }
  end

  # The id of the form of a step: its submit button points to it (form=), wherever the button sits
  CREATION_FORM_ID = "game-table-creation-form".freeze

  # The card that leads to the template builder, first of the row of templates: drawn like the empty spots of
  # "My tables" (dashed border), not as a choice
  CREATE_TEMPLATE_CARD_CLASSES = %w[
    flex h-full min-h-52 flex-col items-center justify-center gap-2 rounded-xl border border-dashed border-field-line
    bg-surface p-4 text-center text-ink transition-colors hover:bg-surface-raised
    focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus-ring
  ].join(" ").freeze

  def creation_form_id
    CREATION_FORM_ID
  end

  def create_template_card_classes
    CREATE_TEMPLATE_CARD_CLASSES
  end

  # Cancel then Continue, at the end of the form on the right: Continue sends the form by its id
  def creation_actions(cancel_path:)
    cancel_link = link_to(t("game_tables.creation_actions.cancel"), cancel_path, class: button_classes(:secondary))
    continue_button = button_tag(t("game_tables.creation_actions.continue"),
                                 type: :submit, form: CREATION_FORM_ID, class: button_classes(:primary))
    cancel_link + continue_button
  end

  def choice_tile_classes
    CHOICE_TILE_CLASSES
  end

  def choice_check_classes
    CHOICE_CHECK_CLASSES
  end

  # Each step of the creation, with its number and its state for the step being filled in
  def creation_steps(current_step)
    current_index = GameTable::CREATION_STEPS.index(current_step)
    GameTable::CREATION_STEPS.each_with_index.map do |step, index|
      { key: step, number: index + 1, state: creation_step_state(step, index, current_index) }
    end
  end

  def step_marker_classes(state)
    STEP_MARKER_CLASSES.fetch(state)
  end

  # On a phone, only the label of the current step shows: five labels do not fit side by side
  def step_label_classes(state)
    state == :current ? "font-semibold text-ink" : "text-muted max-sm:sr-only"
  end

  def step_aria(state)
    state == :current ? { current: "step" } : {}
  end

  # A group of tiles has no Simple Form wrapper: its legend and its error reuse the classes of the fields
  def choice_legend_classes
    SimpleFormFieldClasses::LABEL
  end

  def choice_error_classes
    SimpleFormFieldClasses::ERROR
  end

  # The template is required: once refused, its radio buttons are marked invalid and point to the message
  def sheet_template_choice_aria(game_table)
    return {} unless game_table.errors.include?(:sheet_template)

    { invalid: true, describedby: "sheet-template-error" }
  end

  def cover_choice_label(cover_image)
    t("game_tables.covers.#{cover_image}")
  end

  private

  def creation_step_state(step, index, current_index)
    return :current if index == current_index
    return :coming_soon if GameTable::LATER_CREATION_STEPS.include?(step)

    index < current_index ? :done : :upcoming
  end
end
