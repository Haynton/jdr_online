# The game room of a table (GameRoom, layouts/game_room), a board on the whole screen with floating islands
# (maquette C, decision of 26 November): its name, its settings and the way out at the top, the bar of tools on the
# left, the party at the bottom left, the chat at the bottom right. Each tool opens its panel beside the bar
# (game_room_panels_controller.js), the sheet of a character opens in a window
module GameRoomHelper
  PANEL_ICONS = {
    "character" => "shared/icons/venetian_mask", "npcs" => "shared/icons/skull", "maps" => "shared/icons/map",
    "map_tools" => "shared/icons/cloud_fog", "dice" => "shared/icons/dices",
    "items" => "shared/icons/backpack", "inventory" => "shared/icons/backpack",
    "spells" => "shared/icons/wand_sparkles", "skills" => "shared/icons/list_checks",
    "features" => "shared/icons/sparkles", "details" => "shared/icons/scroll_text"
  }.freeze
  # Written in full, so that a search for the file name finds them (rule of the project)
  PANEL_PARTIALS = {
    "character" => "game_rooms/panels/character", "npcs" => "game_rooms/panels/npcs",
    "maps" => "game_rooms/panels/maps", "items" => "game_rooms/panels/items",
    "inventory" => "game_rooms/panels/inventory", "spells" => "game_rooms/panels/spells",
    "skills" => "game_rooms/panels/skills", "features" => "game_rooms/panels/features",
    "details" => "game_rooms/panels/details",
    "dice" => "game_rooms/panels/dice"
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
  # The cameras (game_rooms/_video): a line at the top, centred, 320 px kept on each side; in the middle
  # (data-size="stage"), the room between the bar of tools, the islands at the top and the strip of the fighters, the
  # places straight on the board (decision: not in a card)
  VIDEO_CLASSES = %w[
    group/video absolute top-4 left-1/2 z-20 hidden max-w-[calc(100%-40rem)] -translate-x-1/2 flex-col items-center
    md:flex data-[size=stage]:top-22 data-[size=stage]:right-4 data-[size=stage]:bottom-22 data-[size=stage]:left-22
    data-[size=stage]:z-30 data-[size=stage]:max-w-none data-[size=stage]:translate-x-0 data-[size=stage]:justify-center
  ].join(" ").freeze
  # Its places: a line that never scrolls (they shrink together); in the middle, large places in rows, each row
  # centred (the last one too, when it is not full)
  VIDEO_PLACES_CLASSES = %w[
    flex max-w-full justify-center gap-2 group-data-[size=stage]/video:max-w-5xl group-data-[size=stage]/video:flex-wrap
    group-data-[size=stage]/video:gap-3
  ].join(" ").freeze
  # One place: 16:9, 107, 160 or 240 px wide (60, 90 or 135 px high), shrinking with the others; 320 px in the
  # middle
  VIDEO_PLACE_CLASSES = %w[
    relative flex aspect-video w-[107px] min-w-0 items-center justify-center overflow-hidden
    group-data-[size=medium]/video:w-40 group-data-[size=large]/video:w-60 group-data-[size=stage]/video:w-80
  ].join(" ").freeze
  # A small button of an island header (the cameras: smaller, larger, fold): an icon alone in 28 px, the size of the
  # quiet buttons of the app would leave no room for the name of the island at its smallest
  ISLAND_HEADER_BUTTON_CLASSES = %w[
    inline-flex size-7 shrink-0 cursor-pointer items-center justify-center rounded-md text-muted transition-colors
    hover:bg-surface-raised hover:text-ink disabled:cursor-default disabled:opacity-40 disabled:hover:bg-transparent
    focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus-ring
  ].join(" ").freeze
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

  # Into the window of the room, never prefetched (an answer laid out for the window must not serve the whole page)
  def character_sheet_dialog_link_data
    { turbo_frame: SHEET_FRAME, turbo_prefetch: false }
  end

  def character_sheet_in_dialog?
    turbo_frame_request_id == SHEET_FRAME
  end
end
