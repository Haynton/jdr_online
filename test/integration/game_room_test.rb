require "test_helper"

# The game room of a table: a board on the whole screen with its islands instead of the navigation of the app, the
# tools of its bar in groups and by role, the party, and the sheet of a character in its window (any player's for the
# game master, their own for a player)
class GameRoomTest < ActionDispatch::IntegrationTest
  GAME_MASTER_TOOLS = ["Cartes", "Outils de carte (bientôt)", "PNJ et ennemis", "Objets", "Dés (bientôt)"].freeze
  PLAYER_TOOLS = ["Ma fiche", "Dés (bientôt)"].freeze

  setup do
    @game_master = create_user("maitre")
    @player = create_user("joueur")
    @other_player = create_user("autre")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, sheet_template: sheet_template,
                                    template_snapshot: sheet_template.snapshot)
    @game_table.participations.create!(user: @game_master, role: :game_master)
    @character = create_character(@player, "Aria")
    @other_character = create_character(@other_player, "Borin")
    @game_table.characters.create!(kind: :monster, name: "Gobelin", visible_to_players: false)
  end

  test "the game master gets the tools of the game master in groups, not the navigation of the app" do
    sign_in @game_master
    get game_table_path(@game_table)

    assert_select "#side-nav", count: 0
    assert_select "h1", text: "La Crypte"
    assert_equal GAME_MASTER_TOOLS, tool_names
    assert_equal %w[Carte Biblio. Dés], css_select("nav [role=group] > span[id^=game-room-tool-group]").map(&:text)
    assert_select "#game-room-panel-npcs", text: /Gobelin/
  end

  test "the strip of the fighters shows the players out of the turns, the game master may start them" do
    sign_in @game_master
    get game_table_path(@game_table)

    assert_select "[data-controller=combat-strip]" do
      assert_select "li[data-side=player]", count: 2
      assert_select "button[data-combat-strip-target=portrait][aria-label^=?]", "Aria"
      assert_select "button[data-action='combat-strip#askInitiative']", text: /Lancer le tour par tour/
      assert_select "button[data-action^='combat-strip#endFight'][data-confirm-question^=?]", "Mettre fin au tour par tour ?"
      assert_select "dialog button[data-action='combat-strip#startWithoutRolls']", text: /Sans jet/
      assert_select "ol[data-action*='combat-strip#pointerDown']"
      assert_select "section[data-combat-strip-target=sheet]", count: 2
    end
  end

  test "a player sees the strip, opens only their own quick sheet and starts no turns" do
    sign_in @player
    get game_table_path(@game_table)

    assert_select "[data-controller=combat-strip]" do
      assert_select "button[data-combat-strip-target=portrait][aria-label^=?]", "Aria"
      assert_select "[role=img][data-combat-strip-target=portrait][aria-label^=?]", "Borin"
      assert_select "section[data-combat-strip-target=sheet]", count: 1
      assert_select "button[data-action='combat-strip#askInitiative']", count: 0
    end
  end

  test "the cameras have a place per person of the table at the top, sized and shown from their buttons and the settings" do
    sign_in @player
    get game_table_path(@game_table)

    assert_select "section[data-controller=video-island] ul#game-room-video-places[data-turbo-permanent] li", count: 3
    assert_select "#game-room-video-places li", text: /Vous/, count: 1
    assert_select "section[data-controller=video-island] button[data-action='video-island#larger']"
    assert_select "#game-room-settings [data-controller=video-settings] [data-video-settings-target=size]", count: 3
  end

  test "the display lets each viewer hide the chat altogether" do
    sign_in @player
    get game_table_path(@game_table)

    assert_select "#game-room-settings [data-controller=chat-visibility][hidden]", text: /Afficher le chat/ do
      assert_select "[role=switch][aria-labelledby=game-room-chat-shown-label]"
    end
    assert_select "aside[data-controller=chat-island][data-action*='game-room-chat:change@window']"
  end

  test "the game master places a creature from its panel, a player has no such button" do
    sign_in @game_master
    get game_table_path(@game_table)
    assert_select "#game-room-npc-list button[data-action='room-board#takeCreature'][data-room-board-name-param=?]", "Gobelin"

    sign_in @player
    get game_table_path(@game_table)
    assert_select "button[data-action='room-board#takeCreature']", count: 0
  end

  test "online, the simulated parts are hidden: no turns, no quick sheets, no placing, each portrait opens the sheet" do
    original_environment = Rails.env
    Rails.env = "production"
    sign_in @game_master
    get game_table_path(@game_table)

    assert_select "[data-action='combat-strip#askInitiative'], [data-combat-strip-target=sheet]", count: 0
    assert_select "[data-room-board-target=creaturePlacer], [data-room-board-target=mapPlacer], [data-room-board-target=map]",
                  count: 0
    assert_select "[data-controller=combat-strip] a[href=?][data-turbo-frame=character_sheet_dialog]",
                  game_table_character_sheet_path(@game_table, @character)
  ensure
    Rails.env = original_environment
  end

  test "the chat has its handle and its button, shown by its controller" do
    sign_in @player
    get game_table_path(@game_table)

    assert_select "aside[data-controller=chat-island]" do
      assert_select "[role=separator][hidden][aria-controls=game-room-chat-body]"
      assert_select "button[hidden][aria-expanded=true][aria-controls=game-room-chat-body]"
    end
  end

  test "adding an NPC, an enemy, an item or a map opens its window in the room, never leaves it" do
    sign_in @game_master
    get game_table_path(@game_table)

    assert_select "#game-room-panel-npcs a[href=?][data-turbo-frame=bestiary_dialog]", game_table_bestiary_path(@game_table)
    assert_select "#game-room-panel-npcs a[href=?][data-turbo-frame=npc_dialog]", new_game_table_npc_path(@game_table)
    assert_select "#game-room-npc-list a[data-turbo-frame=npc_dialog]", text: /Gobelin/
    assert_select "#game-room-panel-items a[href=?][data-turbo-frame=catalog_entry_dialog]",
                  new_game_table_catalog_entry_path(@game_table, kind: "item")
    assert_select "#game-room-panel-npcs a[href=?], #game-room-panel-items a[href^=?]",
                  edit_game_table_cast_path(@game_table), edit_game_table_catalog_path(@game_table), count: 0
    assert_select "dialog#npc-dialog, dialog#bestiary-dialog, dialog#catalog-entry-dialog, dialog#map-dialog", count: 4
    assert_select "#game-room-panel-maps a[href=?][data-turbo-frame=map_dialog]", new_game_table_game_map_path(@game_table)
    assert_select "#game-room-panel-maps a[href=?]", edit_game_table_map_list_path(@game_table), count: 0
  end

  test "a player gets their own sheet, and nothing of the game master" do
    sign_in @player
    get game_table_path(@game_table)

    assert_equal PLAYER_TOOLS, tool_names
    assert_select "#game-room-panel-character a[href=?]", game_table_character_sheet_path(@game_table, @character)
    assert_select "#game-room-panel-npcs, #game-room-panel-items, #game-room-panel-maps", count: 0
    assert_no_match(/Gobelin/, response.body)
    assert_select "dialog#npc-dialog, dialog#bestiary-dialog, dialog#catalog-entry-dialog, dialog#map-dialog", count: 0
    assert_select "#game-room-settings [role=tab]", text: /Participants|Visio et son|Affichage/, count: 3
    assert_select "#game-room-settings", text: /Borin/
    assert_select "#game-room-settings input#game-room-invitation-link", count: 0
    assert_select "#game-room-settings form[action=?]", game_table_settings_path(@game_table), count: 0
  end

  test "the settings of the game master hold the players, the invitation link and the rules, saved back to the room" do
    sign_in @game_master
    get game_table_path(@game_table)

    assert_select "button[data-action='game-room-panels#openSettings'][aria-label=?]", "Paramètres"
    assert_select "#game-room-settings input#game-room-invitation-link[value$=?]", @game_table.invite_token
    assert_select "#game-room-settings a[href^='/game_tables/#{@game_table.id}/']", count: 0

    patch game_table_settings_path(@game_table), params: { back_to: "game_room", game_table: { starting_level: 4 } }
    assert_redirected_to game_table_path(@game_table, settings: "rules")
    assert_equal 4, @game_table.reload.starting_level

    get game_table_path(@game_table, settings: "rules")
    assert_select "[data-game-room-panels-settings-open-value=true]"
  end

  test "the language changed in the room brings back to the room, never to another table" do
    sign_in @player
    patch settings_locale_path, params: { game_table_id: @game_table.id, user: { locale: "en" } }
    assert_redirected_to game_table_path(@game_table, settings: "display")

    other_table = GameTable.create!(name: "Ailleurs")
    patch settings_locale_path, params: { game_table_id: other_table.id, user: { locale: "fr" } }
    assert_redirected_to settings_display_path
  end

  test "the display lets the bar unfold on hover or not, a choice of this browser" do
    sign_in @player
    get game_table_path(@game_table)

    assert_select "#game-room-settings [data-controller=toolbar-hover][hidden]", text: /Déplier la barre au survol/ do
      assert_select "[role=switch][aria-labelledby=game-room-toolbar-hover-label]"
    end
  end

  test "leaving the game is asked first" do
    sign_in @player
    get game_table_path(@game_table)

    question = "Quitter la partie « La Crypte » ? Vous la retrouverez dans « Mes tables »."
    assert_select "form[action=?][method=get][data-turbo-confirm=?][data-confirm-button=?]",
                  game_tables_path, question, "Quitter la partie", count: 1 do
      assert_select "input[type=hidden][name=table][value=?]", @game_table.id.to_s
    end
    assert_select "form[data-turbo-confirm] button[aria-label=?]", "Quitter la partie"
  end

  test "the game master reads the sheet of any player, without the button to change it" do
    sign_in @game_master
    get game_table_character_sheet_path(@game_table, @other_character),
        headers: { "Turbo-Frame" => GameRoomHelper::SHEET_FRAME }

    assert_response :success
    assert_select "turbo-frame#character_sheet_dialog h1", text: /Borin/
    assert_select "a[href=?]", edit_character_path(@other_character), count: 0
  end

  test "a player reads their own sheet, with the button to change it" do
    sign_in @player
    get game_table_character_sheet_path(@game_table, @character)

    assert_response :success
    assert_select "a[href=?]", edit_character_path(@character)
  end

  test "a player cannot read the sheet of another player, nor someone who is not at the table" do
    sign_in @player
    get game_table_character_sheet_path(@game_table, @other_character)
    assert_response :not_found

    invited = create_user("invite")
    @game_table.participations.create!(user: invited, role: :player, status: :pending)
    sign_in invited
    get game_table_character_sheet_path(@game_table, @character)
    assert_response :not_found
  end

  private

  def create_user(username)
    User.create!(email: "#{username}@example.com", username: username, password: TEST_PASSWORD, locale: "fr")
  end

  def create_character(user, name)
    participation = @game_table.participations.create!(user: user, role: :player)
    participation.create_character!(game_table: @game_table, kind: :pc, status: :complete, name: name,
                                    sheet: { "class" => "Mage" })
  end

  def tool_names
    css_select("nav[aria-label='Outils de la partie'] a[data-panel-id]").pluck("aria-label")
  end
end
