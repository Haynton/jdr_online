# The game room of a table as one person sees it, from their participation: the tools of its bar, in groups and by
# role (decision: the game master manages the whole table, a player has their own sheet), the party everyone sees,
# and what each panel reads. The page itself only checks that the person is at the table (GameTablesController#show);
# a player never gets what this object keeps for the game master, the panels are not merely hidden
class GameRoom
  # The bar of the room (maquette C, decision of 26 November): its tools in groups, each group under a short name.
  # The board, the map tools and the dice (the initiative roll included: its panel, decision) come with their own
  # branches (« Bientôt » until then)
  GAME_MASTER_TOOL_GROUPS = {
    "map" => %w[maps map_tools], "library" => %w[npcs items], "dice" => %w[dice]
  }.freeze
  PLAYER_TOOL_GROUPS = { "sheet" => %w[character], "dice" => %w[dice] }.freeze
  COMING_SOON_PANELS = %w[map_tools dice].freeze

  attr_reader :participation

  delegate :game_table, :game_master?, to: :participation

  def initialize(participation)
    @participation = participation
  end

  def tool_groups
    game_master? ? GAME_MASTER_TOOL_GROUPS : PLAYER_TOOL_GROUPS
  end

  def panels
    tool_groups.values.flatten
  end

  def coming_soon?(panel)
    COMING_SOON_PANELS.include?(panel)
  end

  # The sections of the window of the settings of the game (decision: a window, like the settings of the app), in the
  # order of its menu: the rules for the game master only, and only with a template that has them
  def settings_sections
    sections = %w[participants rules video display]
    sections.delete("rules") unless game_master? && game_table.asks_starting_level?
    sections
  end

  # The characters of the players, finished or still being made, by name: the party, seen by everyone at the table
  def party
    game_table.characters.pc.includes(participation: :user, avatar_attachment: :blob).order(:name)
  end

  # The characters the game master may give an item to (the panel « Objets »): the finished characters of the
  # players; none for a player
  def gift_receivers
    game_master? ? party.reject(&:draft?) : []
  end

  # The people of the table in the video call (its places for now, the call comes with Jitsi): the game master, then
  # the players who have accepted, by username
  def video_participations
    game_table.participations.accepted.includes(user: { avatar_attachment: :blob })
              .sort_by { |participation| [participation.game_master? ? 0 : 1, participation.user.username.downcase] }
  end

  # The character of a player, nil while they have none
  def own_character
    participation.character unless game_master?
  end

  def npcs
    game_master? ? game_table.npcs : Character.none
  end

  def game_maps
    game_master? ? game_table.game_maps.with_attached_image : GameMap.none
  end

  # The items the table offers (its catalog: the template's, changed, removed or added for the table), by name
  def items
    return CatalogEntry.none unless game_master?

    Catalogs::TableCatalog.new(game_table).entries("item").reorder(:name)
  end
end
