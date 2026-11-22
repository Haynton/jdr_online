module GameTablesHelper
  # Outline of a table card: a pointed arch of 220 x 310 px, the same as the ogive utility of application.css.
  # The second path is the same outline, drawn 6 px inside
  OGIVE_OUTLINE_PATH = "M0 310V148A154.6 154.6 0 0 1 110 0A154.6 154.6 0 0 1 220 148V310Z".freeze
  OGIVE_INNER_PATH = "M6 304V149A147.6 147.6 0 0 1 110 8A147.6 147.6 0 0 1 214 149V304Z".freeze

  # A view cannot read a constant of a helper, only its methods
  def ogive_outline_path
    OGIVE_OUTLINE_PATH
  end

  def ogive_inner_path
    OGIVE_INNER_PATH
  end

  def default_cover_image_path
    GameTable.cover_image_path(GameTable::DEFAULT_COVER_IMAGE)
  end

  # An invitation not answered yet reads "Invitation" where a table shows the role of the user
  def table_role_label(participation)
    return t("game_tables.invitation.label") if participation.pending?

    t("game_tables.roles.#{participation.role}")
  end

  # An invitation calls for an answer: a badge at the top of its card (game_tables/_ogive_card).
  # Hidden from screen readers: the text of the card already says "Invitation"
  def table_card_attention_badge(participation)
    return unless participation.pending?

    tag.span(class: "#{badge_classes(:invitation)} gap-1.5 shadow-md", aria: { hidden: true }) do
      render("shared/icons/mail", css_class: "size-3.5") + t("game_tables.invitation.label")
    end
  end

  # Beside the role: the status of the table, or who sent the invitation
  def table_detail_label(participation)
    game_table = participation.game_table
    return t("game_tables.invitation.from", username: game_table.game_master&.username) if participation.pending?

    table_status_label(game_table)
  end

  # The main button of the chosen table: its game master finishes setting up a draft, a player without a character
  # makes it, everyone else joins the game
  def stage_main_action_label(participation)
    return t("game_tables.stage.resume_creation") if resuming_creation?(participation)
    return t("game_tables.stage.resume_character") if participation.player? && participation.character&.draft?
    return t("game_tables.stage.create_character") if participation.needs_character?

    t("game_tables.stage.join_game")
  end

  def stage_main_action_path(participation)
    game_table = participation.game_table
    return creation_step_path(game_table, game_table.resume_creation_step) if resuming_creation?(participation)
    return new_game_table_character_path(game_table) if participation.needs_character?

    game_table_path(game_table)
  end

  def resuming_creation?(participation)
    participation.game_master? && participation.game_table.draft?
  end

  def table_players_label(game_table)
    t("game_tables.players", count: game_table.players_count)
  end

  # "draft" while the table is not fully set up, "in_progress" otherwise (GameTable::DRAFT_STATUS)
  def table_status_key(game_table)
    game_table.draft? ? "draft" : "in_progress"
  end

  def table_status_label(game_table)
    t("game_tables.statuses.#{table_status_key(game_table)}")
  end

  # Read by table_filter_controller.js to show or hide the card
  def table_card_filter_data(participation)
    { table_filter_target: "card", role: participation.role, status: table_status_key(participation.game_table) }
  end

  # The pills of the filter: a group (what the card is filtered on) and a value. Within a group, the chosen
  # values add up (GM or player); between the groups, they combine (GM and draft)
  TABLE_FILTERS = [
    { group: "role", value: "game_master", label_key: "game_tables.roles.game_master" },
    { group: "role", value: "player", label_key: "game_tables.roles.player" },
    { group: "status", value: "draft", label_key: "game_tables.statuses.draft" },
    { group: "status", value: "in_progress", label_key: "game_tables.statuses.in_progress" }
  ].freeze

  # Same tonal colors as the game master badge when pressed: a pressed pill must not look like a button
  FILTER_PILL_CLASSES = %w[
    inline-flex h-8 shrink-0 items-center rounded-full border border-line px-3 text-[13px] font-medium text-ink
    transition-colors hover:bg-surface-raised
    aria-pressed:border-primary-soft-ink/50 aria-pressed:bg-primary-soft aria-pressed:text-primary-soft-ink
    focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus-ring
  ].join(" ").freeze

  # The pills by group (role, then status), so that the view can draw a line between the groups
  def table_filter_groups
    TABLE_FILTERS.group_by { |filter| filter[:group] }.values
  end

  def filter_pill_classes
    FILTER_PILL_CLASSES
  end

  # The card of the table shown large at the top is marked for screen readers, and styled by aria-current
  def table_card_aria(participation, chosen_participation)
    participation == chosen_participation ? { current: "true" } : {}
  end

  # A table card only replaces the chosen table (Turbo Frame of game_tables/index) and the address.
  # card_row_controller.js moves the gold outline (aria-current) to it at once: the row is not rendered again
  def table_card_data
    { turbo_frame: "chosen_table", turbo_action: "advance", action: "card-row#choose" }
  end
end
