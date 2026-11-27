require "test_helper"

class CharacterCompanionTest < ActiveSupport::TestCase
  setup do
    @game_table = GameTable.create!(name: "La Crypte", template_snapshot: { "character_fields" => { "fields" => [] } })
    @player_character = player_character_of(@game_table, username: "player", name: "Elowen")
  end

  test "a companion is a creature of the game master, shown at the step NPCs and enemies" do
    companion = @game_table.characters.create!(kind: :companion, name: "Chouette")

    assert_includes Character::GAME_MASTER_KINDS, "companion"
    assert_includes @game_table.npcs, companion
  end

  test "a companion may wait for its owner, then be given to a player character of its table" do
    companion = @game_table.characters.create!(kind: :companion, name: "Chouette")
    assert_nil companion.owner_character

    companion.update!(owner_character: @player_character)

    assert_equal [companion], @player_character.companions.to_a
  end

  test "a companion is never given to a character of another table, nor to an NPC" do
    other_table = GameTable.create!(name: "Ailleurs", template_snapshot: { "character_fields" => { "fields" => [] } })
    stranger = player_character_of(other_table, username: "stranger", name: "Brannoc")
    innkeeper = @game_table.characters.create!(kind: :npc, name: "Aubergiste")

    [stranger, innkeeper].each do |owner|
      companion = @game_table.characters.build(kind: :companion, name: "Chouette", owner_character: owner)
      assert companion.tap(&:validate).errors.of_kind?(:owner_character, :not_a_player_of_the_table)
    end
  end

  test "only a companion has an owner" do
    wolf = @game_table.characters.build(kind: :monster, name: "Loup", owner_character: @player_character)

    assert wolf.tap(&:validate).errors.of_kind?(:owner_character, :only_for_companion)
  end

  test "a companion goes back to the game master when its owner goes" do
    companion = @game_table.characters.create!(kind: :companion, name: "Chouette", owner_character: @player_character)

    @player_character.destroy!

    assert_nil companion.reload.owner_character_id
  end

  private

  def player_character_of(game_table, username:, name:)
    player = User.create!(email: "#{username}@example.com", username: username, password: TEST_PASSWORD)
    participation = game_table.participations.create!(user: player, role: :player)
    game_table.characters.create!(kind: :pc, participation: participation, name: name)
  end
end
