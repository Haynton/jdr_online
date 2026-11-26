require "test_helper"
require "turbo/broadcastable/test_helper"

# The rolls of dice of the game room: rolled by the server for someone accepted at the table, written in the feed
# under the name of who rolled, with the modes the template declares; a hidden roll goes to the game master alone
class GameRoomDiceTest < ActionDispatch::IntegrationTest
  include Turbo::Broadcastable::TestHelper

  ADVANTAGE = { "key" => "advantage", "label" => "Avantage", "dice" => 2, "keep" => "highest" }.freeze
  INITIATIVE = { "label" => "Initiative", "sides" => 20, "modifier_from" => "intelligence" }.freeze

  setup do
    @game_master = create_user("maitre")
    @player = create_user("joueur")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    sheet_template.character_fields["dice_rolls"] = { "modes" => [ADVANTAGE], "modes_on_sides" => 20,
                                                      "initiative" => INITIATIVE }
    sheet_template.save!
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, sheet_template: sheet_template,
                                    template_snapshot: sheet_template.snapshot)
    @game_table.participations.create!(user: @game_master, role: :game_master)
    participation = @game_table.participations.create!(user: @player, role: :player)
    @character = participation.create_character!(game_table: @game_table, kind: :pc, status: :complete,
                                                 name: "Aria", sheet: { "intelligence" => 14 })
    @goblin = @game_table.characters.create!(kind: :monster, status: :complete, name: "Gobelin")
  end

  test "a player rolls: the server rolls, the feed says it under the name of their character" do
    sign_in @player

    assert_turbo_stream_broadcasts(@game_table, count: 1) { roll(count: 3, sides: 6, bonus: 2) }

    assert_response :ok
    line = @game_table.chat_messages.last
    assert_equal "dice_rolled", line.event_key
    assert_equal "Aria", line.event_params["roller"]
    assert_equal "3d6+2", line.event_params["notation"]
    assert_equal line.event_params["dice"].sum + 2, line.event_params["total"]
    assert_select "turbo-stream[action=append][target=game-room-chat-feed]", text: /Aria lance 3d6\+2 :/
  end

  test "advantage is a mode of the template, on its die only" do
    sign_in @player

    roll(count: 1, sides: 20, mode: "advantage")

    params = @game_table.chat_messages.last.event_params
    assert_equal "1d20 (Avantage)", params["notation"]
    assert_equal 2, params["dice"].size
    assert_equal params["dice"].max, params["total"]

    [{ count: 1, sides: 6, mode: "advantage" }, { count: 1, sides: 20, mode: "luck" }].each do |refused|
      assert_no_difference("ChatMessage.count") { roll(**refused) }
      assert_response :unprocessable_content
    end
  end

  test "a roll the panel does not offer is refused" do
    sign_in @player

    [{ count: 1, sides: 7 }, { count: 0, sides: 6 }, { count: 2, sides: 6, bonus: 99 }].each do |refused|
      assert_no_difference("ChatMessage.count") { roll(**refused) }
      assert_response :unprocessable_content
    end
  end

  test "the game master rolls hidden: the line goes to them alone and stays out of the feed of the players" do
    sign_in @game_master

    assert_no_turbo_stream_broadcasts(@game_table) do
      assert_turbo_stream_broadcasts([@game_table, GameTableChannel::GAME_MASTER_AUDIENCE], count: 1) do
        roll(count: 1, sides: 20, hidden: true)
      end
    end

    line = @game_table.chat_messages.last
    assert line.game_master_only?
    assert_equal "dice_rolled_by_game_master", line.event_key
    assert_select "turbo-stream li", text: /Jet caché, vu par vous seul · Le MJ lance 1d20 :/
    assert_equal [line], ChatMessage.feed_of(@game_table, game_master: true)
    assert_empty ChatMessage.feed_of(@game_table)
  end

  test "a player cannot roll hidden: the roll is for the whole table" do
    sign_in @player

    roll(count: 1, sides: 20, hidden: true)

    assert_not @game_table.chat_messages.last.game_master_only?
  end

  test "the room of the game master listens to their own stream, not the room of a player" do
    sign_in @game_master
    get game_table_path(@game_table)
    assert_select "turbo-cable-stream-source[channel=GameTableChannel]", count: 2

    sign_in @player
    get game_table_path(@game_table)
    assert_select "turbo-cable-stream-source[channel=GameTableChannel]", count: 1
  end

  test "the panel offers the dice, the modes of the template, and the hidden roll to the game master only" do
    sign_in @game_master
    get game_table_path(@game_table)

    assert_select "#game-room-panel-dice form[action=?]", game_table_dice_roll_path(@game_table) do
      assert_select "input[type=radio][name='dice_roll[sides]']", count: DiceRolls::Roller::SIDES.size
      assert_select "input[type=radio][name='dice_roll[sides]'][value='20'][checked]"
      assert_select "input[name='dice_roll[count]'][min='1'][max='20']"
      assert_select "input[name='dice_roll[bonus]'][min='-50'][max='50']"
      assert_select "input[type=radio][name='dice_roll[mode]']", count: 2
      assert_select "label", text: /Avantage/
      assert_select "input[type=checkbox][role=switch][name='dice_roll[hidden]']"
    end

    sign_in @player
    get game_table_path(@game_table)
    assert_select "#game-room-panel-dice input[name='dice_roll[hidden]']", count: 0
  end

  test "the roll shows in the panel of who rolled; without JavaScript, back to the room" do
    sign_in @player

    roll(count: 2, sides: 8, bonus: 1)
    line = @game_table.chat_messages.last
    assert_select "turbo-stream[action=replace][target=dice-roll-result]",
                  text: /#{line.event_params['total']}.*2d8\+1/m

    post game_table_dice_roll_path(@game_table), params: { dice_roll: { count: 1, sides: 20 } }
    assert_redirected_to game_table_path(@game_table, anchor: "game-room-panel-dice")
  end

  test "a template without modes shows no mode" do
    @game_table.sheet_template.character_fields.delete("dice_rolls")
    @game_table.sheet_template.save!
    @game_table.update!(template_snapshot: @game_table.sheet_template.snapshot)
    sign_in @player
    get game_table_path(@game_table)

    assert_select "#game-room-panel-dice input[name='dice_roll[mode]']", count: 0
    assert_select "#game-room-panel-dice input[name='dice_roll[sides]']", count: DiceRolls::Roller::SIDES.size
  end

  test "a player rolls the initiative of their character: the die of the template plus the value of its sheet" do
    sign_in @player

    roll(initiative: 1, mode: "advantage", count: 3, sides: 6, bonus: 9, character_id: @goblin.id)

    params = @game_table.chat_messages.last.event_params
    assert_equal "initiative_rolled", @game_table.chat_messages.last.event_key
    assert_equal "Aria", params["character"]
    assert_equal "1d20+2 (Avantage)", params["notation"]
    assert_equal params["dice"].max + 2, params["total"]
    assert_select "turbo-stream[target=game-room-chat-feed]", text: /Aria · Initiative : 1d20\+2 \(Avantage\)/
  end

  test "the game master rolls the initiative of an NPC, hidden if they wish" do
    sign_in @game_master

    roll(initiative: 1, character_id: @goblin.id, hidden: true)

    line = @game_table.chat_messages.last
    assert line.game_master_only?
    assert_equal ["Gobelin", "1d20"], line.event_params.values_at("character", "notation")
  end

  test "the panel offers the initiative to who has someone to roll for" do
    sign_in @game_master
    get game_table_path(@game_table)
    assert_select "#game-room-panel-dice select[name='dice_roll[character_id]']" do
      assert_select "optgroup[label=Joueurs] option[value=?]", @character.id.to_s, text: "Aria"
      assert_select "optgroup[label=?] option[value=?]", "PNJ et ennemis", @goblin.id.to_s, text: "Gobelin"
    end
    assert_select "#game-room-panel-dice button[name='dice_roll[initiative]']", text: /Lancer « Initiative »/

    sign_in @player
    get game_table_path(@game_table)
    assert_select "#game-room-panel-dice button[name='dice_roll[initiative]']"
    assert_select "#game-room-panel-dice select[name='dice_roll[character_id]']", count: 0
  end

  test "the initiative is refused without a finished character, or for a character of another table" do
    @character.update!(status: :draft)
    sign_in @player
    assert_no_difference("ChatMessage.count") { roll(initiative: 1) }
    assert_response :unprocessable_content

    sign_in @game_master
    stranger_table = GameTable.create!(name: "Ailleurs", status: GameTable::READY_STATUS)
    stranger_npc = stranger_table.characters.create!(kind: :monster, status: :complete, name: "Loup")
    assert_no_difference("ChatMessage.count") { roll(initiative: 1, character_id: stranger_npc.id) }
    assert_response :unprocessable_content
  end

  test "someone who is not accepted at the table cannot roll" do
    invited = create_user("invite")
    @game_table.participations.create!(user: invited, role: :player, status: :pending)

    [create_user("inconnu"), invited].each do |user|
      sign_in user
      roll(count: 1, sides: 20)
      assert_response :not_found
    end
    assert_equal 0, @game_table.chat_messages.count
  end

  private

  def roll(**dice_roll)
    post game_table_dice_roll_path(@game_table), params: { dice_roll: }, as: :turbo_stream
  end

  def create_user(username)
    User.create!(email: "#{username}@example.com", username: username, password: TEST_PASSWORD, locale: "fr")
  end
end
