require "test_helper"

# « Changer mes maîtrises » in the game room: the player of a complete character whose class gives them changes their
# fighting style and weapon masteries, written in the chat; more than the class gives is refused; anyone else, a 404
class WeaponMasteryChoicesTest < ActionDispatch::IntegrationTest
  setup do
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS,
                                    template_snapshot: WeaponMasteryTemplate.snapshot)
    WeaponMasteryTemplate.add_weapons(@game_table)
    @game_master = User.create!(email: "mj@example.com", username: "maitre", password: TEST_PASSWORD)
    @game_table.participations.create!(user: @game_master, role: :game_master)
    @player = User.create!(email: "player@example.com", username: "joueur", password: TEST_PASSWORD)
    participation = @game_table.participations.create!(user: @player, role: :player)
    @character = @game_table.characters.create!(kind: :pc, participation: participation, name: "Brunhild",
                                                sheet: { "class" => "Guerrier", "strength" => 14, "dexterity" => 14 })
  end

  test "a player changes their style and masteries, written in the chat; more than the class gives is refused" do
    sign_in @player
    get edit_game_table_weapon_mastery_choice_path(@game_table)
    assert_response :success
    assert_select "input[name='character[fighting_style]'][value=archery]"

    patch game_table_weapon_mastery_choice_path(@game_table),
          params: { character: { fighting_style: "archery", weapon_mastery_keys: ["", "longbows"] } }, as: :turbo_stream

    assert_equal ["archery", ["longbows"]], @character.reload.values_at(:fighting_style, :weapon_masteries)
    assert_equal "weapon_masteries_changed", ChatMessage.last.event_key

    patch game_table_weapon_mastery_choice_path(@game_table),
          params: { character: { weapon_mastery_keys: %w[longbows longswords daggers] } }, as: :turbo_stream
    assert_response :unprocessable_content
    assert_equal ["longbows"], @character.reload.weapon_masteries
  end

  test "the game master has no masteries to change" do
    sign_in @game_master
    get edit_game_table_weapon_mastery_choice_path(@game_table)

    assert_response :not_found
  end
end
