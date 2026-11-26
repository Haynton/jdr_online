require "test_helper"
require "turbo/broadcastable/test_helper"

# The rolls of dice of the game room: rolled by the server for someone accepted at the table, written in the feed
# under the name of who rolled, with the modes the template declares; a hidden roll goes to the game master alone
class GameRoomDiceTest < ActionDispatch::IntegrationTest
  include Turbo::Broadcastable::TestHelper

  ADVANTAGE = { "key" => "advantage", "label" => "Avantage", "dice" => 2, "keep" => "highest" }.freeze

  setup do
    @game_master = create_user("maitre")
    @player = create_user("joueur")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    sheet_template.character_fields["dice_rolls"] = { "modes" => [ADVANTAGE], "modes_on_sides" => 20 }
    sheet_template.save!
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, sheet_template: sheet_template,
                                    template_snapshot: sheet_template.snapshot)
    @game_table.participations.create!(user: @game_master, role: :game_master)
    participation = @game_table.participations.create!(user: @player, role: :player)
    participation.create_character!(game_table: @game_table, kind: :pc, status: :complete, name: "Aria")
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
