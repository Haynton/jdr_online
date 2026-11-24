require "test_helper"

# A table deleted by its game master from its page Informations, a draft or a table ready
class TableDeletionTest < ActionDispatch::IntegrationTest
  setup do
    @game_master = User.create!(email: "gm@example.com", username: "maitre", password: TEST_PASSWORD, locale: "fr")
    @game_table = GameTableCreator.new(user: @game_master, attributes: { name: "La Crypte" },
                                       sheet_template: SheetTemplate.create!(name: "Fantasy", locale: "fr")).call
    @player = User.create!(email: "player@example.com", username: "joueur", password: TEST_PASSWORD, locale: "fr")
    participation = @game_table.participations.create!(user: @player, role: "player")
    @game_table.characters.create!(kind: "pc", participation: participation, name: "Lia", status: "draft")
  end

  test "the page Informations of a draft and of a table ready offers to delete it, after a question" do
    sign_in @game_master
    get edit_game_table_details_path(@game_table)
    assert_select "button[form=delete-game-table][data-turbo-confirm=?]",
                  "Supprimer la table « La Crypte » ? Ses personnages et ses PNJ seront supprimés pour tous ses joueurs.",
                  text: "Supprimer la table"
    assert_select "form#delete-game-table[action=?]", game_table_path(@game_table)

    @game_table.finish_creation!
    get edit_game_table_details_path(@game_table)
    assert_select "button[form=delete-game-table]"
  end

  test "the game master deletes the table, with its players and their characters" do
    sign_in @game_master

    assert_difference -> { GameTable.count } => -1, -> { Participation.count } => -2, -> { Character.count } => -1 do
      delete game_table_path(@game_table)
    end
    assert_redirected_to game_tables_path
    assert_equal "Table « La Crypte » supprimée.", flash[:screen_reader_notice]
  end

  test "a player cannot delete the table" do
    sign_in @player

    assert_no_difference -> { GameTable.count } do
      delete game_table_path(@game_table)
    end
    assert_response :not_found
  end

  test "a new table offers no deletion" do
    sign_in @game_master
    get new_game_table_path

    assert_select "#delete-game-table", count: 0
  end
end
