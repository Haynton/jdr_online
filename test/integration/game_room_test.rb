require "test_helper"
require "turbo/broadcastable/test_helper"

# The game room of a table: a board on the whole screen with its islands instead of the navigation of the app, the
# tools of its bar in groups and by role, the party, and the sheet of a character in its window (any player's for the
# game master, their own for a player)
class GameRoomTest < ActionDispatch::IntegrationTest
  include Turbo::Broadcastable::TestHelper

  GAME_MASTER_TOOLS = ["Cartes", "Outils de carte (bientôt)", "PNJ et ennemis", "Objets", "Dés"].freeze
  # The fields of the game the template declares, as the heroic fantasy: hit points, temporary ones, inspiration
  VITAL_FIELDS = [
    { "key" => "hp", "label" => "Points de vie", "type" => "resource", "receives_damage" => true,
      "on_rest" => "reset_to_max", "at_creation" => false, "section" => "Notes" },
    { "key" => "temp_hp", "label" => "PV temporaires", "type" => "resource", "absorbs_damage_for" => "hp",
      "at_creation" => false, "section" => "Notes" },
    { "key" => "inspiration", "label" => "Inspiration", "type" => "boolean", "at_creation" => false, "section" => "Notes" },
    { "key" => "armor_class_bonus", "label" => "Bonus de CA", "type" => "number", "at_creation" => false,
      "game_master_adjusts" => true, "min" => -10, "max" => 10, "section" => "Notes" },
    { "key" => "armor_class", "label" => "Classe d'armure", "type" => "computed", "rule" => "worn_armor_class",
      "based_on" => "intelligence", "bonus_from" => "armor_class_bonus", "section" => "Notes" },
    { "key" => "silver", "label" => "Pièces d'argent", "abbreviation" => "pa", "type" => "number", "min" => 0,
      "max" => 100, "at_creation" => false, "currency" => true, "section" => "Notes" }
  ].freeze
  DEATH_SAVE_FIELDS = [
    { "key" => "death_successes", "label" => "Réussites", "type" => "number", "at_creation" => false,
      "internal" => true, "section" => "Notes" },
    { "key" => "death_failures", "label" => "Échecs", "type" => "number", "at_creation" => false, "internal" => true,
      "section" => "Notes" }
  ].freeze
  DEATH_SAVES = { "label" => "Jets contre la mort", "sides" => 20, "success_from" => 10, "needed" => 3,
                  "successes_from" => "death_successes", "failures_from" => "death_failures" }.freeze
  RESOURCE = { "key" => "arcane_recovery", "label" => "Restauration arcanique", "uses" => [1] * 20,
               "recovery" => "long_rest" }.freeze
  PLAYER_TOOLS = ["Ma fiche", "Inventaire", "Détails", "Dés"].freeze

  setup do
    @game_master = create_user("maitre")
    @player = create_user("joueur")
    @other_player = create_user("autre")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template(extra_fields: VITAL_FIELDS)
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

  test "a player sees the strip, their own portrait opens their panel, no quick sheet, no turns" do
    sign_in @player
    get game_table_path(@game_table)

    assert_select "[data-controller=combat-strip]" do
      assert_select "button[data-panel-id=game-room-panel-character][data-action='game-room-panels#toggle']" \
                    "[aria-controls=game-room-panel-character]", count: 1
      assert_select "[role=img][data-combat-strip-target=portrait][aria-label^=?]", "Borin"
      assert_select "section[data-combat-strip-target=sheet]", count: 0
      assert_select "button[data-action='combat-strip#askInitiative']", count: 0
    end
  end

  test "a player has their inventory, and their spells only when they have some" do
    @character.inventory_items.create!(key: "dagger", name: "Dague", quantity: 2, description: "Une lame courte.")
    sign_in @player
    get game_table_path(@game_table)

    assert_select "#game-room-panel-inventory", text: /2 × Dague/
    assert_select "#game-room-panel-spells", count: 0
    assert_select "[data-controller~=details-dialog] dialog#details-dialog", count: 1

    @character.update_columns(spells: [{ "key" => "fire-bolt", "name" => "Trait de feu", "level" => 0,
                                         "properties" => { "school" => "Évocation" } }])
    sign_in @player
    get game_table_path(@game_table)

    assert_includes tool_names, "Sorts"
    assert_select "#game-room-panel-spells", text: /Trait de feu/
  end

  test "a player takes their items away one by one, the last one asked first, and the panel is redrawn" do
    dagger = @character.inventory_items.create!(key: "dagger", name: "Dague", quantity: 2)
    sign_in @player
    get game_table_path(@game_table)

    assert_select "#game-room-inventory form[action=?]:not([data-turbo-confirm])",
                  game_table_inventory_item_path(@game_table, dagger)

    delete game_table_inventory_item_path(@game_table, dagger), as: :turbo_stream

    assert_equal 1, dagger.reload.quantity
    assert_select "turbo-stream[action=replace][target=game-room-inventory]"
    assert_select "#game-room-inventory form[data-turbo-confirm^=?]", "Retirer « Dague » de l'inventaire ?"

    delete game_table_inventory_item_path(@game_table, dagger), as: :turbo_stream

    assert_not InventoryItem.exists?(dagger.id)
  end

  test "a player equips an armour, a shield or a weapon, one armour at a time, and the panel is redrawn" do
    leather = @character.inventory_items.create!(key: "leather-armor", name: "Armure de cuir", equipped: true,
                                                 properties: { "armor_base" => 11 })
    chain_mail = @character.inventory_items.create!(key: "chain-mail", name: "Cotte de mailles",
                                                    properties: { "armor_base" => 16, "armor_dexterity_cap" => 0 })
    rope = @character.inventory_items.create!(key: "rope", name: "Corde")
    sign_in @player
    get game_table_path(@game_table)

    assert_select "#game-room-inventory input[role=switch][aria-label=?]:not([checked])", "Équiper « Cotte de mailles »"
    assert_select "#game-room-inventory input[role=switch][aria-label=?]", "Équiper « Corde »", count: 0

    @character.update_columns(sheet: @character.sheet.merge("intelligence" => 14))
    assert_turbo_stream_broadcasts @game_table do
      patch game_table_inventory_item_path(@game_table, chain_mail), params: { equipped: "1" }, as: :turbo_stream
    end

    assert_select "turbo-stream[action=replace][target=game-room-inventory]"
    assert_select "turbo-stream[action=replace][target=?]", "character-#{@character.id}-armor-class", text: "16"
    assert_select "turbo-stream[action=replace][target=?]", "character-#{@character.id}-attacks"
    assert chain_mail.reload.equipped
    assert_not leather.reload.equipped

    patch game_table_inventory_item_path(@game_table, rope), params: { equipped: "1" }, as: :turbo_stream
    assert_response :not_found
    assert_not rope.reload.equipped
  end

  test "nobody equips an item of someone else's character, the game master neither" do
    sword = @other_character.inventory_items.create!(key: "longsword", name: "Épée longue",
                                                     properties: { "damage_dice" => "1d8" })

    [@player, @game_master].each do |user|
      sign_in user
      patch game_table_inventory_item_path(@game_table, sword), params: { equipped: "1" }, as: :turbo_stream

      assert_response :not_found
    end
    assert_not sword.reload.equipped
  end

  test "a player adds coins to their purse or takes some out, never below 0 nor above the most of the coin" do
    sign_in @player
    get game_table_path(@game_table)
    assert_select "#game-room-inventory form[action=?] select[name=coin] option[value=silver]",
                  game_table_purse_path(@game_table)

    patch game_table_purse_path(@game_table), params: { coin: "silver", amount: 8, direction: "add" }, as: :turbo_stream
    assert_equal 8, @character.reload.sheet["silver"]
    assert_select "turbo-stream[action=replace][target=game-room-inventory]"

    patch game_table_purse_path(@game_table), params: { coin: "silver", amount: 3, direction: "remove" },
                                              as: :turbo_stream
    assert_equal 5, @character.reload.sheet["silver"]

    patch game_table_purse_path(@game_table), params: { coin: "silver", amount: 9, direction: "remove" },
                                              as: :turbo_stream
    assert_response :unprocessable_content
    assert_select "#game-room-purse-error", text: "Il n'y a que 5 pa dans la bourse."

    patch game_table_purse_path(@game_table), params: { coin: "silver", amount: 200, direction: "add" }, as: :turbo_stream
    assert_response :unprocessable_content
    assert_equal 5, @character.reload.sheet["silver"]
  end

  test "nobody fills the purse of a coin the template does not declare, nor the game master their own" do
    sign_in @player
    patch game_table_purse_path(@game_table), params: { coin: "hp", amount: 8, direction: "add" }, as: :turbo_stream
    assert_response :not_found

    sign_in @game_master
    patch game_table_purse_path(@game_table), params: { coin: "silver", amount: 8, direction: "add" }, as: :turbo_stream
    assert_response :not_found
  end

  test "the game master gives money to a player, written in the chat; a player never does" do
    sign_in @game_master
    get game_table_path(@game_table)
    assert_select "dialog form[action=?] select[name=coin]", game_table_money_gift_path(@game_table)

    post game_table_money_gift_path(@game_table), params: { character_id: @character.id, coin: "silver", amount: 12 }

    assert_redirected_to game_table_path(@game_table)
    assert_equal 12, @character.reload.sheet["silver"]
    assert_equal({ "count" => 12, "coin" => "pa", "character" => "Aria" }, ChatMessage.last.event_params)

    sign_in @player
    post game_table_money_gift_path(@game_table), params: { character_id: @character.id, coin: "silver", amount: 12 }
    assert_response :not_found
    assert_equal 12, @character.reload.sheet["silver"]
  end

  test "a player spends gold pieces, never more than they have" do
    @character.update_columns(sheet: @character.sheet.merge("gold" => 7))
    sign_in @player
    get game_table_path(@game_table)

    assert_select "#game-room-inventory form[action=?] input[name=amount][max='7']",
                  game_table_inventory_value_path(@game_table, "gold")

    patch game_table_inventory_value_path(@game_table, "gold"), params: { amount: 5 }, as: :turbo_stream

    assert_equal 2, @character.reload.sheet["gold"]
    assert_select "turbo-stream[action=replace][target=game-room-inventory]"

    patch game_table_inventory_value_path(@game_table, "gold"), params: { amount: 3 }, as: :turbo_stream

    assert_response :unprocessable_content
    assert_select "#inventory-value-gold-error", text: "Indiquez une somme de 1 à 2."
    assert_equal 2, @character.reload.sheet["gold"]
  end

  test "nobody spends the gold of someone else's character, nor a value that is not kept with the inventory" do
    @other_character.update_columns(sheet: @other_character.sheet.merge("gold" => 7))
    sign_in @player
    patch game_table_inventory_value_path(@game_table, "level"), params: { amount: 1 }, as: :turbo_stream

    assert_response :not_found

    sign_in @game_master
    patch game_table_inventory_value_path(@game_table, "gold"), params: { amount: 1 }, as: :turbo_stream

    assert_response :not_found
    assert_equal 7, @other_character.reload.sheet["gold"]
  end

  test "nobody takes away an item of someone else's character, the game master neither" do
    dagger = @other_character.inventory_items.create!(key: "dagger", name: "Dague", quantity: 2)

    [@player, @game_master].each do |user|
      sign_in user
      delete game_table_inventory_item_path(@game_table, dagger), as: :turbo_stream

      assert_response :not_found
    end
    assert_equal 2, dagger.reload.quantity
  end

  test "the panel of a player holds their abilities and their fight card" do
    sign_in @player
    get game_table_path(@game_table)

    assert_select "#game-room-panel-character" do
      assert_select "#game-room-own-abilities", text: "Caractéristiques"
      assert_select "[data-controller=fighter-card][data-fighter-card-name-value=Aria]"
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
    assert_select "aside[data-controller~=chat-island][data-action*='game-room-chat:change@window']"
  end

  test "the game master places a creature from its panel, a player has no such button" do
    sign_in @game_master
    get game_table_path(@game_table)
    assert_select "#game-room-npc-list button[data-action='room-board#takeCreature'][data-room-board-name-param=?]", "Gobelin"

    sign_in @player
    get game_table_path(@game_table)
    assert_select "button[data-action='room-board#takeCreature']", count: 0
  end

  test "online, the simulated parts are hidden: no turns, no placing, no conditions; the quick sheets are saved" do
    original_environment = Rails.env
    Rails.env = "production"
    sign_in @game_master
    get game_table_path(@game_table)

    assert_select "[data-action='combat-strip#askInitiative']", count: 0
    assert_select "[data-room-board-target=creaturePlacer]", count: 0
    assert_select "[data-action='fighter-card#changeHitPoints'], [data-action='fighter-card#openConditions']", count: 0
    assert_select "section[data-combat-strip-target=sheet]", count: 2
    assert_select "section#combat-sheet-character-#{@character.id} a[href=?][data-turbo-frame=character_sheet_dialog]",
                  game_table_character_sheet_path(@game_table, @character)
  ensure
    Rails.env = original_environment
  end

  test "the game master changes the hit points, temporary hit points and inspiration of a player, shared at once" do
    @character.update_columns(sheet: @character.sheet.merge("hp" => { "current" => 10, "max" => 12 }))
    sign_in @game_master
    get game_table_path(@game_table)

    assert_select "section#combat-sheet-character-#{@character.id}" do
      assert_select "form[action=?] input[name=hit_points_delta][value='-1']",
                    game_table_character_vital_path(@game_table, @character)
      assert_select "form[action=?]", long_rest_game_table_character_vital_path(@game_table, @character)
    end

    assert_turbo_stream_broadcasts @game_table do
      patch game_table_character_vital_path(@game_table, @character), params: { hit_points_delta: -3 },
                                                                       as: :turbo_stream
    end
    assert_select "turbo-stream[action=replace][target=?]", "character-#{@character.id}-hit-points", text: %r{7/12}
    assert_equal 7, @character.reload.sheet.dig("hp", "current")

    post long_rest_game_table_character_vital_path(@game_table, @character), as: :turbo_stream
    assert_equal 12, @character.reload.sheet.dig("hp", "current")
  end

  test "the game master adjusts the bonus to the armour class of a player, and the armour class is shared at once" do
    @character.update_columns(sheet: @character.sheet.merge("intelligence" => 14, "hp" => { "current" => 10, "max" => 12 }))
    @character.inventory_items.create!(name: "Cotte de mailles", equipped: true,
                                       properties: { "armor_base" => 16, "armor_dexterity_cap" => 0 })
    sign_in @game_master
    get game_table_path(@game_table)

    assert_select "section#combat-sheet-character-#{@character.id}" do
      assert_select "#character-#{@character.id}-armor-class", text: "16"
      assert_select "form[action=?] input[name=adjust][value=armor_class_bonus]",
                    game_table_character_vital_path(@game_table, @character)
    end

    assert_turbo_stream_broadcasts @game_table do
      patch game_table_character_vital_path(@game_table, @character),
            params: { adjust: "armor_class_bonus", adjust_delta: 2 }, as: :turbo_stream
    end
    assert_equal 2, @character.reload.sheet["armor_class_bonus"]
    assert_select "turbo-stream[action=replace][target=?]", "character-#{@character.id}-armor-class", text: "18"
    assert_select "turbo-stream[action=replace][target=?]", "character-#{@character.id}-adjusted-armor_class_bonus",
                  text: "+2"
  end

  test "a player never adjusts the bonus to the armour class, and does not see it in their panel" do
    sign_in @player
    get game_table_path(@game_table)
    assert_select "#game-room-panel-character input[name=adjust]", count: 0

    patch game_table_character_vital_path(@game_table, @character),
          params: { adjust: "armor_class_bonus", adjust_delta: 2 }, as: :turbo_stream

    assert_response :not_found
    assert_nil @character.reload.sheet["armor_class_bonus"]
  end

  test "at 0 hit points, a player rolls their death save, written in the chat; a hit at 0 is a failure" do
    @game_table.update!(template_snapshot: @game_table.template_snapshot.deep_merge("character_fields" => {
      "fields" => @game_table.template_snapshot.dig("character_fields", "fields") + DEATH_SAVE_FIELDS,
      "death_saves" => DEATH_SAVES
    }))
    @character.update_columns(sheet: @character.sheet.merge("hp" => { "current" => 0, "max" => 12 }))
    sign_in @player
    get game_table_path(@game_table)
    assert_select "#character-#{@character.id}-death-saves form[action=?]",
                  death_save_game_table_character_vital_path(@game_table, @character)

    post death_save_game_table_character_vital_path(@game_table, @character), as: :turbo_stream

    assert_response :success
    assert_equal 1, @character.reload.sheet.values_at("death_successes", "death_failures").compact.sum
    assert_match(/\Adeath_save_/, ChatMessage.last.event_key)
    assert_select "turbo-stream[action=replace][target=?]", "character-#{@character.id}-death-saves"

    sign_in @game_master
    patch game_table_character_vital_path(@game_table, @character), params: { hit_points_delta: -1 }, as: :turbo_stream
    assert_operator @character.reload.sheet["death_failures"].to_i, :>=, 1
  end

  test "nobody rolls a death save above 0 hit points, nor for someone else's character" do
    @character.update_columns(sheet: @character.sheet.merge("hp" => { "current" => 5, "max" => 12 }))
    sign_in @player
    post death_save_game_table_character_vital_path(@game_table, @character), as: :turbo_stream
    assert_response :not_found

    sign_in @player
    post death_save_game_table_character_vital_path(@game_table, @other_character), as: :turbo_stream
    assert_response :not_found
  end

  test "a player spends a resource of their class, written in the chat; the game master gives it back with a rest" do
    @game_table.update!(template_snapshot: @game_table.template_snapshot.deep_merge("character_fields" => {
      "fields" => @game_table.template_snapshot.dig("character_fields", "fields").map do |field|
        next field unless field["key"] == "class"

        field.deep_merge("effects" => { "Mage" => { "resources" => [RESOURCE] } })
      end
    }))
    sign_in @player
    get game_table_path(@game_table)
    path = game_table_character_vital_resource_path(@game_table, @character, "arcane_recovery")
    assert_select "#character-#{@character.id}-resources form[action=?]", path

    patch path, params: { resource_change: "spend" }, as: :turbo_stream
    assert_equal({ "arcane_recovery" => 1 }, @character.reload.resources_used)
    assert_equal "resource_used", ChatMessage.last.event_key
    assert_select "turbo-stream[action=replace][target=?]", "character-#{@character.id}-resources"

    patch path, params: { resource_change: "spend" }, as: :turbo_stream
    assert_response :unprocessable_content

    sign_in @player
    post short_rest_game_table_character_vital_path(@game_table, @character), as: :turbo_stream
    assert_response :not_found

    sign_in @game_master
    post long_rest_game_table_character_vital_path(@game_table, @character), as: :turbo_stream
    assert_empty @character.reload.resources_used
  end

  test "a player spends a spell slot, written in the chat of the game master only; a long rest gives it back" do
    sign_in @game_master
    get game_table_path(@game_table)
    path = game_table_character_vital_spell_slot_path(@game_table, @character, 1)
    assert_select "#character-#{@character.id}-spell-slots form[action=?]", path

    sign_in @player
    patch path, params: { resource_change: "spend" }, as: :turbo_stream
    assert_equal({ "1" => 1 }, @character.reload.spell_slots_used)
    assert_predicate ChatMessage.last, :game_master_only?
    assert_equal "spell_slot_spent", ChatMessage.last.event_key

    2.times { patch path, params: { resource_change: "spend" }, as: :turbo_stream }
    assert_response :unprocessable_content

    sign_in @game_master
    post long_rest_game_table_character_vital_path(@game_table, @character), as: :turbo_stream
    assert_empty @character.reload.spell_slots_used
  end

  test "a player changes the hit points of their own character only, and never takes a long rest" do
    @character.update_columns(sheet: @character.sheet.merge("hp" => { "current" => 10, "max" => 12 }))
    @other_character.update_columns(sheet: @other_character.sheet.merge("hp" => { "current" => 10, "max" => 12 }))
    sign_in @player
    patch game_table_character_vital_path(@game_table, @character), params: { hit_points_delta: 1 }, as: :turbo_stream

    assert_equal 11, @character.reload.sheet.dig("hp", "current")

    patch game_table_character_vital_path(@game_table, @other_character), params: { hit_points_delta: -1 },
                                                                           as: :turbo_stream
    assert_response :not_found

    sign_in @player
    post long_rest_game_table_character_vital_path(@game_table, @character), as: :turbo_stream
    assert_response :not_found
    assert_equal 10, @other_character.reload.sheet.dig("hp", "current")
  end

  test "the chat has its handle and its button, shown by its controller" do
    sign_in @player
    get game_table_path(@game_table)

    assert_select "aside[data-controller~=chat-island]" do
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
    assert_select "#game-room-panel-character a[href=?][data-turbo-frame=?]", edit_character_path(@character),
                  GameRoomHelper::SHEET_FRAME, text: /Modifier ma fiche/
    assert_select "#game-room-panel-details", text: /Niveau/
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

  test "a player changes their character in the window of the room, which is refreshed once saved" do
    sign_in @player
    frame = { "Turbo-Frame" => GameRoomHelper::SHEET_FRAME }
    get edit_character_path(@character), headers: frame

    assert_select "turbo-frame##{GameRoomHelper::SHEET_FRAME}" do
      assert_select "h2#character-sheet-dialog-title", text: "Modifier Aria"
      assert_select "form[action=?]", character_path(@character)
      assert_select "button[data-action='frame-dialog#close']", text: "Annuler"
    end

    patch character_path(@character), params: { character: { name: "Aria la Brave" } }, headers: frame

    assert_response :success
    assert_match(/<turbo-stream action="refresh"/, response.body)
    assert_equal "Aria la Brave", @character.reload.name
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
