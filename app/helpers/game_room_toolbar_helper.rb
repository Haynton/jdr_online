# The classes of the bar of tools of the game room (game_rooms/_toolbar, game_rooms/_tool_group_name), written
# once: its width that slides, its tools, their names, the names of its groups
module GameRoomToolbarHelper
  # The bar of tools from 768 px (game_rooms/_toolbar): 60 px wide while folded, like the islands at the top are high
  # (decision), its icons centred; it unfolds to
  # 240 px when it is hovered (after 150 ms, so that it never opens when the mouse only passes) or when the keyboard is
  # in it (a visible focus only: a panel closed with the mouse gives the focus back to its tool without a ring), and
  # folds back once a tool is chosen, until the mouse leaves it (data-retracted, game_room_panels_controller.js).
  # Hovering it can be turned off in the display of the settings of the game (data-hover-off,
  # toolbar_hover_controller.js): the keyboard still unfolds it.
  # Decision of 26 November (Anthony's request, smoother): only the width of the bar slides, in 200 ms, the names
  # wait in place, cut by its edge, and fade in once it is open; no slide if the device asks for less motion
  TOOLBAR_WIDTH_CLASSES = %w[
    md:w-15 md:overflow-x-hidden md:overflow-y-auto motion-safe:md:transition-[width] md:duration-200 md:ease-out
    md:[&:hover:not([data-retracted]):not([data-hover-off])]:w-60
    md:[&:hover:not([data-retracted]):not([data-hover-off])]:delay-150
    md:[&:has(:focus-visible):not([data-retracted])]:w-60
  ].join(" ").freeze
  # A tool of the bar: a square of 44 px on a phone; from 768 px, the whole width of the bar (46 px folded), its icon
  # 13 px from its left edge, centred in the folded bar and its name beside it
  TOOLBAR_TOOL_CLASSES = %w[
    relative flex size-11 shrink-0 items-center justify-center rounded-lg text-muted transition-colors
    md:w-full md:justify-start md:px-[13px]
    hover:bg-surface-raised hover:text-ink aria-expanded:bg-surface-raised aria-expanded:text-ink
    focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus-ring
  ].join(" ").freeze
  # The name of a tool, beside its icon, always in place (cut by the edge of the folded bar), faded in once the bar is
  # open; read by screen readers through the aria-label of the tool. Not on a phone
  TOOLBAR_LABEL_CLASSES = %w[
    hidden ml-3 min-w-0 text-sm font-medium whitespace-nowrap opacity-0 md:block
    motion-safe:transition-opacity motion-safe:duration-150
    md:group-[:hover:not([data-retracted]):not([data-hover-off])]/bar:opacity-100
    md:group-[:hover:not([data-retracted]):not([data-hover-off])]/bar:delay-200
    md:group-[:has(:focus-visible):not([data-retracted])]/bar:opacity-100
  ].join(" ").freeze
  # The name of a group of tools, written twice in the same place (decision: no jump): short and centred over the
  # folded bar, then on the left, over the names, once it is open, the one fading into the other
  TOOLBAR_GROUP_NAME_CLASSES = %w[
    col-start-1 row-start-1 text-[10px] leading-none font-semibold tracking-wider whitespace-nowrap text-muted uppercase
    motion-safe:transition-opacity motion-safe:duration-150
  ].join(" ").freeze
  TOOLBAR_GROUP_NAME_FOLDED_CLASSES = %w[
    flex w-full justify-center md:group-[:hover:not([data-retracted]):not([data-hover-off])]/bar:opacity-0
    md:group-[:has(:focus-visible):not([data-retracted])]/bar:opacity-0
  ].join(" ").freeze
  TOOLBAR_GROUP_NAME_OPEN_CLASSES = %w[
    px-3 opacity-0 md:group-[:hover:not([data-retracted]):not([data-hover-off])]/bar:opacity-100
    md:group-[:hover:not([data-retracted]):not([data-hover-off])]/bar:delay-200
    md:group-[:has(:focus-visible):not([data-retracted])]/bar:opacity-100
  ].join(" ").freeze
end
