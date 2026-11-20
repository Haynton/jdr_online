require "test_helper"

class ParticipationTest < ActiveSupport::TestCase
  setup do
    @game_table = GameTable.create!(name: "Les Marches du Nord")
    @game_master = create_user("game_master")
    @player = create_user("player")
  end

  test "someone who joins a table is a player by default" do
    participation = @game_table.participations.create!(user: @player)

    assert participation.player?
  end

  test "a table has only one game master" do
    @game_table.participations.create!(user: @game_master, role: :game_master)
    second_game_master = @game_table.participations.build(user: @player, role: :game_master)

    assert_not second_game_master.valid?
    assert_includes second_game_master.errors[:game_table_id], error_message(:game_table_id, :game_master_taken)
  end

  test "a table can have several players" do
    @game_table.participations.create!(user: @game_master, role: :player)

    assert @game_table.participations.build(user: @player, role: :player).valid?
  end

  test "a user joins a table only once" do
    @game_table.participations.create!(user: @player)
    second_participation = @game_table.participations.build(user: @player)

    assert_not second_participation.valid?
    assert_includes second_participation.errors[:user_id], error_message(:user_id, :already_at_table)
  end

  test "the same user can be game master at one table and player at another" do
    other_table = GameTable.create!(name: "L'Ombre du Dragon")
    @game_table.participations.create!(user: @game_master, role: :game_master)

    assert other_table.participations.build(user: @game_master, role: :player).valid?
  end

  test "an unknown role is refused" do
    assert_raises(ArgumentError) { @game_table.participations.build(user: @player, role: "wizard") }
  end

  test "a user reaches their tables through their participations" do
    @game_table.participations.create!(user: @player)

    assert_equal [@game_table], @player.game_tables.to_a
  end

  private

  def create_user(username)
    User.create!(email: "#{username}@example.com", username: username, password: TEST_PASSWORD)
  end

  def error_message(attribute, error_key)
    I18n.t("activerecord.errors.models.participation.attributes.#{attribute}.#{error_key}")
  end
end
