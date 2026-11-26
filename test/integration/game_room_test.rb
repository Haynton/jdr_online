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
    assert_equal %w[Carte Biblio. Dés Joueurs], css_select("nav [role=group] > span[id^=game-room-tool-group]").map(&:text)
    assert_select "#game-room-panel-npcs", text: /Gobelin/
  end

  test "the players are at the foot of the bar, with their hit points, the sheet only for who may read it" do
    add_hit_points_to_the_copy_of_the_template
    @character.update_columns(sheet: { "class" => "Mage", "hp" => { "current" => 7, "max" => 12 } })
    sign_in @game_master
    get game_table_path(@game_table)

    assert_select "nav [role=group][aria-labelledby=game-room-tool-group-players]" do
      assert_select "a[href=?][data-turbo-frame=character_sheet_dialog][aria-label=?]",
                    game_table_character_sheet_path(@game_table, @character),
                    "Aria, Points de vie : 7 sur 12, ouvrir sa fiche"
      assert_select "a[href=?]", game_table_character_sheet_path(@game_table, @other_character)
      assert_select "circle[style=?]", "stroke-dasharray: 58 100"
    end

    sign_in @player
    get game_table_path(@game_table)
    assert_select "nav [role=group][aria-labelledby=game-room-tool-group-players]" do
      assert_select "a[href=?]", game_table_character_sheet_path(@game_table, @character)
      assert_select "a[href=?]", game_table_character_sheet_path(@game_table, @other_character), count: 0
      assert_select "[role=img][aria-label=?]", "Borin"
    end
  end

  test "the chat has its handle and its button, shown by its controller" do
    sign_in @player
    get game_table_path(@game_table)

    assert_select "aside[data-controller=chat-island]" do
      assert_select "[role=separator][hidden][aria-controls=game-room-chat-body]"
      assert_select "button[hidden][aria-expanded=true][aria-controls=game-room-chat-body]"
    end
  end

  test "adding an NPC, an enemy or an item opens its window in the room, never leaves it" do
    sign_in @game_master
    get game_table_path(@game_table)

    assert_select "#game-room-panel-npcs a[href=?][data-turbo-frame=bestiary_dialog]", game_table_bestiary_path(@game_table)
    assert_select "#game-room-panel-npcs a[href=?][data-turbo-frame=npc_dialog]", new_game_table_npc_path(@game_table)
    assert_select "#game-room-npc-list a[data-turbo-frame=npc_dialog]", text: /Gobelin/
    assert_select "#game-room-panel-items a[href=?][data-turbo-frame=catalog_entry_dialog]",
                  new_game_table_catalog_entry_path(@game_table, kind: "item")
    assert_select "#game-room-panel-npcs a[href=?], #game-room-panel-items a[href^=?]",
                  edit_game_table_cast_path(@game_table), edit_game_table_catalog_path(@game_table), count: 0
    assert_select "dialog#npc-dialog, dialog#bestiary-dialog, dialog#catalog-entry-dialog", count: 3
  end

  test "a player gets their own sheet, and nothing of the game master" do
    sign_in @player
    get game_table_path(@game_table)

    assert_equal PLAYER_TOOLS, tool_names
    assert_select "#game-room-panel-character a[href=?]", game_table_character_sheet_path(@game_table, @character)
    assert_select "#game-room-panel-npcs, #game-room-panel-items, #game-room-panel-maps", count: 0
    assert_no_match(/Gobelin/, response.body)
    assert_select "dialog#npc-dialog, dialog#bestiary-dialog, dialog#catalog-entry-dialog", count: 0
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

  # The field that takes the damage, shown to the others, as the templates of the app declare it
  def add_hit_points_to_the_copy_of_the_template
    hit_points = { "key" => "hp", "label" => "Points de vie", "type" => "resource", "at_creation" => false,
                   "receives_damage" => true, "visible_to_others" => true }
    snapshot = @game_table.template_snapshot.deep_dup
    snapshot["character_fields"]["fields"] << hit_points
    @game_table.update_column(:template_snapshot, snapshot)
  end

  def tool_names
    css_select("nav[aria-label='Outils de la partie'] a[data-panel-id]").pluck("aria-label")
  end
end
