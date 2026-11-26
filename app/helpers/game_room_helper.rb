# The game room of a table (GameRoom, layouts/game_room), a board on the whole screen with floating islands
# (maquette C, decision of 26 November): its name, its settings and the way out at the top, the bar of tools on the
# left, the party at the bottom left, the chat at the bottom right. Each tool opens its panel beside the bar
# (game_room_panels_controller.js), the sheet of a character opens in a window
module GameRoomHelper
  PANEL_ICONS = {
    "character" => "shared/icons/venetian_mask", "npcs" => "shared/icons/skull", "maps" => "shared/icons/map",
    "map_tools" => "shared/icons/cloud_fog", "dice" => "shared/icons/dices",
    "items" => "shared/icons/backpack"
  }.freeze
  # Written in full, so that a search for the file name finds them (rule of the project)
  PANEL_PARTIALS = {
    "character" => "game_rooms/panels/character", "npcs" => "game_rooms/panels/npcs",
    "maps" => "game_rooms/panels/maps", "items" => "game_rooms/panels/items"
  }.freeze
  # The sections of the window of the settings, written in full too (GameRoom#settings_sections)
  SETTINGS_PARTIALS = {
    "participants" => "game_rooms/settings/participants", "rules" => "game_rooms/settings/rules",
    "video" => "game_rooms/settings/video", "display" => "game_rooms/settings/display"
  }.freeze
  # A section of the menu of the window, like a section link of the settings window of the app
  # (SettingsDialogHelper): its text in muted, the section shown in surface-raised and ink
  SETTINGS_TAB_CLASSES = %w[
    flex shrink-0 items-center rounded-lg px-3 py-1.5 text-left text-[15px] whitespace-nowrap text-muted
    transition-colors hover:bg-surface-raised hover:text-ink aria-selected:bg-surface-raised aria-selected:text-ink
    focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus-ring
  ].join(" ").freeze
  COMING_SOON_PARTIAL = "game_rooms/panels/coming_soon".freeze
  SHEET_FRAME = "character_sheet_dialog".freeze

  # An island over the board: a card of surface with its thin border and a shadow, which detaches it from the map
  ISLAND_CLASSES = "rounded-xl border border-line bg-surface shadow-lg".freeze
  # A button of the islands (settings, the way out), an icon alone in a square of 44 px, its name in its tooltip and
  # for screen readers; the open panel in surface-raised, like the current page in the navigation of the app
  TOOL_CLASSES = %w[
    group relative flex size-11 shrink-0 items-center justify-center rounded-lg text-muted transition-colors
    hover:bg-surface-raised hover:text-ink aria-expanded:bg-surface-raised aria-expanded:text-ink
    focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus-ring
  ].join(" ").freeze
  # The name of the island buttons at the top right, shown when they are hovered or reached with the keyboard, under
  # them, after 150 ms. Hidden from screen readers: the button is named by its aria-label. Ink on page: 14 and more
  TOOLTIP_CLASSES = %w[
    pointer-events-none absolute top-full right-0 z-40 mt-2 rounded-md bg-ink px-2 py-1 text-xs font-medium
    whitespace-nowrap text-page opacity-0 shadow-md transition-opacity group-hover:opacity-100 group-hover:delay-150
    group-focus-visible:opacity-100
  ].join(" ").freeze

  def game_room_panel_id(panel)
    "game-room-panel-#{panel.dasherize}"
  end

  def game_room_panel_icon(panel)
    PANEL_ICONS.fetch(panel)
  end

  # The name of a tool, « (bientôt) » after it for a tool to come
  def game_room_tool_name(game_room, panel)
    name = t("game_rooms.panels.#{panel}.title")
    game_room.coming_soon?(panel) ? t("game_rooms.toolbar.coming_soon_label", name: name) : name
  end

  # The section shown first: the one the server came back to (?settings=rules after the rules were saved), else the
  # first one
  def game_room_settings_index(game_room)
    game_room.settings_sections.index(params[:settings]).to_i
  end

  def game_room_settings_open?(game_room)
    game_room.settings_sections.include?(params[:settings])
  end

  def game_room_panel_partial(game_room, panel)
    game_room.coming_soon?(panel) ? COMING_SOON_PARTIAL : PANEL_PARTIALS.fetch(panel)
  end

  # Leaving the game is asked first in the confirmation window, from a form that sends a GET to « Mes tables »
  # (button_to): Turbo asks only for a form, and the window reads its button text on the form (a link made into a
  # form by Turbo loses it)
  def leave_game_form_data(game_room)
    { turbo_confirm: t("game_rooms.top_bar.leave_confirm", name: game_room.game_table.name),
      confirm_button: t("game_rooms.top_bar.leave") }
  end

  # The current value and the maximum of the gauge of the party (the hit points) on the sheet of a character, nil
  # while it has none (a character still being made)
  def party_gauge(character, field)
    value = character.sheet.to_h[field["key"]] if field
    return unless value.is_a?(Hash) && value["max"].to_i.positive?

    { current: value["current"].to_i.clamp(0, value["max"].to_i), max: value["max"].to_i }
  end

  # How much of the gauge is left, from 0 to 100: the length of the ring around the avatar of a player (pathLength
  # 100) and of the bar beside their name, computed values written in an inline style (never a class built by
  # interpolation)
  def party_gauge_percent(gauge)
    (100.0 * gauge[:current] / gauge[:max]).round
  end

  # The name of a player in the bar, for screen readers: their name, their gauge if any, and what a click does
  def party_member_name(game_room, character, gauge)
    parts = [character_display_name(character)]
    parts << party_gauge_text(game_room, gauge) if gauge
    parts << t("game_rooms.party.draft") if character.draft?
    parts << t("game_rooms.party.open_sheet") if game_room.may_read_sheet?(character)
    parts.join(", ")
  end

  def party_gauge_text(game_room, gauge)
    t("game_rooms.party.gauge", label: game_room.party_gauge_field["label"], current: gauge[:current], max: gauge[:max])
  end

  # Into the window of the room, never prefetched (an answer laid out for the window must not serve the whole page)
  def character_sheet_dialog_link_data
    { turbo_frame: SHEET_FRAME, turbo_prefetch: false }
  end

  def character_sheet_in_dialog?
    turbo_frame_request_id == SHEET_FRAME
  end
end
