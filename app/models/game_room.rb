# The game room of a table as one person sees it, from their participation: the tools of its bar, in groups and by
# role (decision: the game master manages the whole table, a player has their own sheet), the party everyone sees,
# and what each panel reads. The page itself only checks that the person is at the table (GameTablesController#show);
# a player never gets what this object keeps for the game master, the panels are not merely hidden
class GameRoom
  # The bar of the room (maquette C, decision of 26 November): its tools in groups, each group under a short name.
  # The map tools come with their own branch (« Bientôt » until then); the initiative roll will join the panel of
  # the dice (decision); the budget of an encounter and the prices of what is paid without being carried (the inn, a
  # hireling) only when the template declares them (TemplateCopy#encounters, #rule_sheets, #price_lists)
  GAME_MASTER_TOOL_GROUPS = {
    "map" => %w[maps map_tools], "library" => %w[npcs items encounter rules prices], "dice" => %w[dice]
  }.freeze
  # A player's sheet in its tools (decision of 26 November: every piece of information of the sheet has its panel):
  # their character in a fight, their skills, their inventory, their spells, their features, the rest of their sheet
  PLAYER_TOOL_GROUPS = { "sheet" => %w[character skills inventory spells features details], "dice" => %w[dice] }.freeze
  COMING_SOON_PANELS = %w[map_tools].freeze

  # The parts of the room that are still simulated in the page of the game master (nothing saved, nothing shared: the
  # board and its placing, the turn by turn, the quick sheet that changes hit points and conditions), shown in
  # development and in the tests only (decision of 26 November: a player online never meets a feature that forgets
  # what it did). docs/salle-de-jeu.md says what each one needs to be wired
  def self.preview_features?
    Rails.env.local?
  end

  attr_reader :participation

  delegate :game_table, :game_master?, to: :participation

  def initialize(participation)
    @participation = participation
  end

  # The last lines of the feed of the table, the oldest first (the chat); the hidden rolls for the game master only
  def chat_feed
    ChatMessage.feed_of(game_table, game_master: game_master?)
  end

  # A tool with nothing in it is left out: « Sorts » for a character without spells, « Compétences » for a template
  # without bonus rows, « Capacités » for options that name no features
  def tool_groups
    return game_master_tool_groups if game_master?

    PLAYER_TOOL_GROUPS.transform_values { |panels| panels - empty_player_panels }
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

  # Who may roll initiative from the panel « Dés »: the game master for the NPCs and enemies of the table (decision:
  # each player rolls their own), a player for their own finished character (DiceRolls::InitiativeRecorder checks
  # it again)
  def initiative_characters
    return game_table.npcs.to_a if game_master?

    [participation.character].compact.reject(&:draft?)
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

  # The budget of an encounter, the rule sheets and the prices only when the template declares them
  def game_master_tool_groups
    missing = []
    missing << "encounter" if game_table.encounters.blank?
    missing << "rules" if game_table.rule_sheets.empty?
    missing << "prices" if game_table.price_lists.empty?
    GAME_MASTER_TOOL_GROUPS.transform_values { |panels| panels - missing }
  end

  def empty_player_panels
    character = own_character
    panels = []
    panels << "spells" if character&.spells.blank?
    panels << "skills" unless character&.sheet_fields.to_a.any? { |field| field["type"] == "bonus" }
    panels << "features" if character.nil? || CharacterSheets::Features.new(character).call.empty?
    panels
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

    Catalogs::TableCatalog.new(game_table).entries("item").where.not("properties ? 'applies_to'").reorder(:name)
  end

  # The magic the game master may put on an item when giving it (Catalogs::Enchantments)
  def enchantments
    return [] unless game_master?

    Catalogs::Enchantments.new(game_table).all
  end
end
