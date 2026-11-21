require "test_helper"

class PlayerInvitationTest < ActiveSupport::TestCase
  setup do
    @game_master = create_user("master")
    @player = create_user("Luara")
    @game_table = GameTableCreator.new(user: @game_master, attributes: { name: "Les Marches du Nord" },
                                       sheet_template: SheetTemplate.create!(name: "Fantasy", locale: "fr")).call
  end

  test "inviting a player makes a pending player participation" do
    invitation = PlayerInvitation.new(game_table: @game_table, username: "Luara")

    assert invitation.save
    assert invitation.participation.pending?
    assert invitation.participation.player?
    assert_equal @player, invitation.participation.user
  end

  test "the username is found whatever its case, and given back as the player wrote it" do
    invitation = PlayerInvitation.new(game_table: @game_table, username: "  luara ")

    assert invitation.save
    assert_equal "Luara", invitation.invited_username
  end

  test "a username is required" do
    invitation = PlayerInvitation.new(game_table: @game_table, username: "")

    assert_not invitation.save
    assert invitation.errors.of_kind?(:username, :blank)
  end

  test "a username nobody has is refused" do
    invitation = PlayerInvitation.new(game_table: @game_table, username: "personne")

    assert_not invitation.save
    assert invitation.errors.of_kind?(:username, :not_found)
  end

  test "a player cannot be invited twice, nor the game master to their own table" do
    PlayerInvitation.new(game_table: @game_table, username: "Luara").save

    [@player, @game_master].each do |user|
      invitation = PlayerInvitation.new(game_table: @game_table, username: user.username)

      assert_not invitation.save
      assert invitation.errors.of_kind?(:username, :already_at_table)
    end
  end

  test "a pending invitation neither counts as a player nor opens the table to the player" do
    PlayerInvitation.new(game_table: @game_table, username: "Luara").save
    @game_table.reload

    assert_equal 0, @game_table.players_count
    assert_equal [@player], @game_table.player_participations.map(&:user)
    assert_not_includes @player.game_tables, @game_table
  end

  private

  def create_user(username)
    User.create!(email: "#{username.downcase}@example.com", username: username, password: TEST_PASSWORD)
  end
end
