require "test_helper"

# The step "NPCs and enemies" of a table: an empty list at first, creatures copied from the bestiary (numbered when
# added again), an NPC created, changed, shown to the players and deleted in its window, never a player character
class TableNpcsStepTest < ActionDispatch::IntegrationTest
  NPC_HEADERS = { "Turbo-Frame" => GameTables::NpcDialogHelper::NPC_FRAME }.freeze
  BESTIARY_HEADERS = { "Turbo-Frame" => GameTables::NpcDialogHelper::BESTIARY_FRAME }.freeze
  NPC_FIELDS = [
    { "key" => "challenge", "label" => "Facteur de puissance", "abbreviation" => "FP", "type" => "choice",
      "options" => %w[0 1/4 1/2 1], "listed" => true, "section" => "Identité" },
    { "key" => "armor_class", "label" => "Classe d'armure", "abbreviation" => "CA", "type" => "number", "min" => 0,
      "max" => 30, "listed" => true, "section" => "Combat" },
    { "key" => "hp", "label" => "Points de vie", "abbreviation" => "PV", "type" => "resource", "listed" => true,
      "section" => "Combat" },
    { "key" => "attacks", "label" => "Attaques", "type" => "attacks", "section" => "Combat" }
  ].freeze

  setup do
    @user = User.create!(email: "gm@example.com", username: "maitre", password: TEST_PASSWORD, locale: "fr")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    sheet_template.update!(npc_fields: { "fields" => NPC_FIELDS })
    add_creature(sheet_template, "goblin-warrior", "Guerrier gobelin", "1/4")
    add_creature(sheet_template, "wolf", "Loup", "1/4")
    add_creature(sheet_template, "ghoul", "Goule", "1")
    @game_table = GameTableCreator.new(user: @user, attributes: { name: "La Crypte" },
                                       sheet_template: sheet_template).call
    sign_in @user
  end

  test "the step starts empty, with the bestiary and an empty window to add NPCs" do
    get edit_game_table_cast_path(@game_table)

    assert_response :success
    assert_select "h1", text: "PNJ et ennemis"
    assert_select "#cast-list", text: /Aucun PNJ pour l'instant/
    assert_select "a[href=?][data-turbo-frame=bestiary_dialog]", game_table_bestiary_path(@game_table)
    assert_select "a[href=?][data-turbo-frame=npc_dialog]", new_game_table_npc_path(@game_table)
  end

  test "the bestiary lists the creatures of the catalog by challenge rating, each with Add" do
    get game_table_bestiary_path(@game_table), headers: BESTIARY_HEADERS

    assert_select "turbo-frame#bestiary_dialog" do
      assert_select "h2#bestiary-dialog-title", text: "Bestiaire"
      assert_equal ["FP 1/4", "FP 1"], css_select("section h3").map(&:text)
      assert_select "li", text: /Guerrier gobelin\s*FP 1\/4 · CA 15 · PV 10/
      assert_select "button[title=?]", "Ajouter Loup"
    end
  end

  test "a creature added from the bestiary is copied, numbered when added again, the bestiary staying open" do
    post game_table_npcs_path(@game_table), params: { catalog_key: "goblin-warrior" }, headers: BESTIARY_HEADERS
    post game_table_npcs_path(@game_table), params: { catalog_key: "goblin-warrior" }, headers: BESTIARY_HEADERS

    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, %(target="cast-list")
    assert_includes response.body, "Ajouté à la table : Guerrier gobelin 2."
    goblins = @game_table.npcs.to_a
    assert_equal ["Guerrier gobelin", "Guerrier gobelin 2"], goblins.map(&:name)
    assert goblins.all?(&:monster?)
    assert goblins.none?(&:visible_to_players)
    assert_equal({ "current" => 10, "max" => 10 }, goblins.first.sheet["hp"])
    assert_equal "Cimeterre", goblins.first.sheet["attacks"].first["name"]
  end

  test "a creature the table does not offer is not found" do
    @game_table.update!(disabled_catalog_keys: { "monster" => ["wolf"] })
    post game_table_npcs_path(@game_table), params: { catalog_key: "wolf" }

    assert_response :not_found
  end

  test "an NPC created in its window: its name, its role, its sheet and its attacks, the list refreshed" do
    post game_table_npcs_path(@game_table), headers: NPC_HEADERS, params: { npc: {
      name: "Aubergiste", kind: "npc", gm_notes: "Espionne pour la guilde.",
      sheet: { challenge: "0", armor_class: "10", hp: "4",
               attacks: { "0" => { name: "Gourdin", to_hit: "+2", damage: "1d4", range: "Allonge 1,50 m" },
                          "1" => { name: "", to_hit: "", damage: "", range: "" } } }
    } }

    assert_includes response.body, %(action="refresh")
    npc = @game_table.npcs.sole
    assert npc.npc?
    assert_not npc.visible_to_players
    assert_equal "Espionne pour la guilde.", npc.gm_notes
    assert_equal({ "current" => 4, "max" => 4 }, npc.sheet["hp"])
    assert_equal [{ "name" => "Gourdin", "to_hit" => 2, "damage" => "1d4", "range" => "Allonge 1,50 m" }],
                 npc.sheet["attacks"]
  end

  test "a refused NPC keeps its window with its errors" do
    post game_table_npcs_path(@game_table), headers: NPC_HEADERS, params: { npc: {
      name: "", sheet: { armor_class: "99", attacks: { "0" => { name: "", to_hit: "4" } } }
    } }

    assert_response :unprocessable_content
    assert_select "turbo-frame#npc_dialog" do
      assert_select "input[name='npc[sheet][armor_class]'][aria-invalid]"
      assert_select "p", text: /chaque attaque doit avoir un nom/
    end
    assert_empty @game_table.npcs
  end

  test "the list shows each NPC with its values, hidden from the players, and its window deletes it" do
    goblin = Catalogs::CreatureCopier.new(@game_table).call("goblin-warrior")
    get edit_game_table_cast_path(@game_table)

    assert_select "li", text: /Guerrier gobelin\s*Ennemi · FP 1\/4 · CA 15 · PV 10/
    assert_select "#cast-list input[role=switch]", count: 0
    patch game_table_npc_path(@game_table, goblin), params: { npc: { visible_to_players: "1" } }
    assert_not goblin.reload.visible_to_players

    delete game_table_npc_path(@game_table, goblin), headers: NPC_HEADERS
    assert_empty @game_table.npcs
  end

  test "a player character is never opened as an NPC, and another game master gets a 404" do
    player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD)
    participation = @game_table.participations.create!(user: player, role: :player)
    character = @game_table.characters.create!(kind: :pc, participation: participation, name: "Elya")

    get edit_game_table_npc_path(@game_table, character)
    assert_response :not_found

    sign_in player
    get edit_game_table_cast_path(@game_table)
    assert_response :not_found
  end

  test "continue reaches the step and opens the summary" do
    patch game_table_cast_path(@game_table)

    assert_redirected_to game_table_summary_path(@game_table)
    assert_equal "summary", @game_table.reload.resume_creation_step
  end

  private

  def add_creature(sheet_template, key, name, challenge)
    sheet_template.catalog_entries.create!(kind: "monster", key: key, name: name, properties: {
      "challenge" => challenge, "armor_class" => 15, "hp" => { "current" => 10, "max" => 10 },
      "attacks" => [{ "name" => "Cimeterre", "to_hit" => 4, "damage" => "1d6+2 tranchants" }]
    })
  end
end
