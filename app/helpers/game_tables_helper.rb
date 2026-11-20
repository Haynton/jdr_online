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

  def table_role_label(participation)
    t("game_tables.roles.#{participation.role}")
  end

  def table_players_label(game_table)
    t("game_tables.players", count: game_table.players_count)
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
