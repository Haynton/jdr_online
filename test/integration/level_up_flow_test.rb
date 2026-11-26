require "test_helper"

# The game master gives a level from the quick sheet of a player in the game room; the player makes its choices in the
# window of the room. Nobody else does either
class LevelUpFlowTest < ActionDispatch::IntegrationTest
  setup do
    template_file = Rails.root.join("db/seeds/sheet_templates/heroic_fantasy.fr.json")
    template = SheetTemplate.find_or_create_by!(JSON.parse(template_file.read(encoding: "UTF-8")))
    @game_table = GameTable.new(name: "La Crypte", starting_level: 3, status: GameTable::READY_STATUS)
    @game_table.use_sheet_template(template)
    @game_table.save!
    @game_master = User.create!(email: "gm@example.com", username: "maitre", password: TEST_PASSWORD, locale: "fr")
    @player = User.create!(email: "player@example.com", username: "joueur", password: TEST_PASSWORD, locale: "fr")
    @game_table.participations.create!(user: @game_master, role: :game_master)
    participation = @game_table.participations.create!(user: @player, role: :player)
    @character = participation.create_character!(
      game_table: @game_table, kind: :pc, status: :complete, name: "Brunhild",
      sheet: { "class" => "Guerrier", "subclass" => "Champion", "level" => 3, "strength" => 15, "constitution" => 14,
               "hp" => { "current" => 28, "max" => 28 } }
    )
  end

  test "the game master gives a level, said in the chat; the player makes its choices and reaches it" do
    sign_in @game_master
    get game_table_path(@game_table)
    assert_select "form[action=?]", game_table_level_grant_path(@game_table, character_id: @character.id)

    post game_table_level_grant_path(@game_table, character_id: @character.id), as: :turbo_stream
    assert_equal 4, @character.reload.level_up_to
    assert_equal "level_granted", @game_table.chat_messages.last.event_key

    sign_in @player
    get game_table_path(@game_table)
    assert_select "a[href=?]", new_game_table_level_up_path(@game_table), text: "Passer au niveau 4"
    get new_game_table_level_up_path(@game_table)
    assert_select "legend", text: "Amélioration de caractéristique"

    post game_table_level_up_path(@game_table), params: { level_up: { ability_increases: { strength: "1" } } }
    assert_response :unprocessable_content
    post game_table_level_up_path(@game_table), params: { level_up: { ability_increases: { strength: "2" } } },
                                                as: :turbo_stream
    assert_equal [4, nil, 36], [@character.reload.sheet["level"], @character.level_up_to, @character.sheet.dig("hp", "max")]
  end

  test "a player never gives a level, nor makes the choices of a level not given" do
    sign_in @player
    post game_table_level_grant_path(@game_table, character_id: @character.id)
    assert_response :not_found

    sign_in @player
    get new_game_table_level_up_path(@game_table)
    assert_response :not_found
  end
end
