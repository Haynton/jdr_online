require "test_helper"

# The live streams of a table: its people only, the stream of the game master for them alone
class GameTableChannelTest < ActionCable::Channel::TestCase
  setup do
    @game_master = create_user("maitre")
    @player = create_user("joueur")
    @game_table = GameTableCreator.new(user: @game_master, attributes: { name: "La Crypte" },
                                       sheet_template: SheetTemplate.create!(name: "Fantasy", locale: "fr")).call
    @game_table.participations.create!(user: @player, role: "player")
  end

  test "the game master and a player of the table hear its stream" do
    [@game_master, @player].each do |user|
      listen_as(user, GameTableChannel.signed_stream_name_for(@game_table))

      assert subscription.confirmed?
      assert_has_stream Turbo::StreamsChannel.send(:stream_name_from, [@game_table])
    end
  end

  test "someone who is not at the table, or only invited, does not" do
    listen_as(create_user("inconnu"), GameTableChannel.signed_stream_name_for(@game_table))
    assert subscription.rejected?

    invited = create_user("invite")
    @game_table.participations.create!(user: invited, role: "player", status: "pending")
    listen_as(invited, GameTableChannel.signed_stream_name_for(@game_table))
    assert subscription.rejected?
  end

  test "the stream of the game master is for the game master only" do
    game_master_stream = GameTableChannel.signed_stream_name_for(@game_table, game_master_only: true)

    listen_as(@player, game_master_stream)
    assert subscription.rejected?

    listen_as(@game_master, game_master_stream)
    assert subscription.confirmed?
    assert_has_stream Turbo::StreamsChannel.send(:stream_name_from, [@game_table, "game_master"])
  end

  test "the stream of a participation is for its own person only, never for the game master nor another player" do
    participation = @game_table.participations.find_by!(user: @player)
    other_player = create_user("autre")
    @game_table.participations.create!(user: other_player, role: "player")
    own_stream = GameTableChannel.signed_stream_name_for(@game_table, participation:)

    [@game_master, other_player].each do |stranger|
      listen_as(stranger, own_stream)
      assert subscription.rejected?, stranger.username
    end

    listen_as(@player, own_stream)
    assert subscription.confirmed?
    assert_has_stream Turbo::StreamsChannel.send(:stream_name_from, [@game_table, participation])
  end

  test "the stream of a participation at another table is refused, even for its own person" do
    other_table = GameTableCreator.new(user: @game_master, attributes: { name: "Le Phare" },
                                       sheet_template: SheetTemplate.create!(name: "Autre", locale: "fr")).call
    elsewhere = other_table.participations.create!(user: @player, role: "player")

    listen_as(@player, GameTableChannel.signed_stream_name_for(@game_table, participation: elsewhere))

    assert subscription.rejected?
  end

  test "a player removed from the table no longer hears it" do
    signed_stream_name = GameTableChannel.signed_stream_name_for(@game_table)
    @game_table.participations.find_by!(user: @player).destroy

    listen_as(@player, signed_stream_name)

    assert subscription.rejected?
  end

  test "a name signed for Turbo's own channel is refused, and a name of this channel is refused by Turbo's" do
    listen_as(@player, Turbo::StreamsChannel.signed_stream_name(@game_table))
    assert subscription.rejected?

    signed_for_this_channel = GameTableChannel.signed_stream_name_for(@game_table)
    assert_nil Turbo::StreamsChannel.verified_stream_name(signed_for_this_channel)
  end

  test "a name not signed at all is refused" do
    listen_as(@player, Turbo::StreamsChannel.send(:stream_name_from, [@game_table]))

    assert subscription.rejected?
  end

  private

  def create_user(username)
    User.create!(email: "#{username}@example.com", username: username, password: TEST_PASSWORD)
  end

  def listen_as(user, signed_stream_name)
    stub_connection current_user: user
    subscribe signed_stream_name: signed_stream_name
  end
end
