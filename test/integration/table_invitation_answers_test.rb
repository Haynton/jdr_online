require "test_helper"

class TableInvitationAnswersTest < ActionDispatch::IntegrationTest
  setup do
    @game_master = User.create!(email: "julien@example.com", username: "Julien", password: TEST_PASSWORD)
    @player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
    @game_table = GameTable.create!(name: "La Crypte", cover_image: "dragon", status: GameTable::READY_STATUS)
    @game_table.participations.create!(user: @game_master, role: :game_master)
  end

  test "an invitation to a ready table comes first in my tables, chosen at the top, with accept and decline" do
    own_table = GameTable.create!(name: "Les Marches du Nord")
    own_table.participations.create!(user: @player, role: :game_master)
    invite_player
    sign_in @player
    get game_tables_path

    assert_select "#{cards_row_selector} > li:nth-child(2) a[aria-current=true]", text: /La Crypte/ do
      assert_select "span", text: "Invitation"
      assert_select "span", text: "· de Julien"
    end
    assert_select "section[aria-labelledby=chosen-table-title]" do
      assert_select "h1", text: "La Crypte"
      assert_select "form[action=?] button", game_table_invitation_answer_path(@game_table), text: "Accepter"
      assert_select "form[action=?][data-turbo-confirm=?] button", game_table_invitation_answer_path(@game_table),
                    "Refuser l'invitation à « La Crypte » ?", text: "Refuser"
      assert_select "a", text: "Rejoindre la partie", count: 0
    end
  end

  test "an invitation to a draft is not shown yet" do
    @game_table.update!(status: GameTable::DRAFT_STATUS)
    invite_player
    sign_in @player
    get game_tables_path

    assert_select "#{cards_row_selector} a", text: /La Crypte/, count: 0
  end

  test "accepting makes the table one of mine, chosen at the top with join the game" do
    invitation = invite_player
    sign_in @player
    patch game_table_invitation_answer_path(@game_table)

    assert invitation.reload.accepted?
    assert_redirected_to game_tables_path(table: @game_table.id)
    follow_redirect!
    assert_select "section[aria-labelledby=chosen-table-title]" do
      assert_select "span", text: "Joueur"
      assert_select "a[href=?]", game_table_path(@game_table), text: "Rejoindre la partie"
    end
  end

  test "declining removes the invitation" do
    invite_player
    sign_in @player
    delete game_table_invitation_answer_path(@game_table)

    assert_redirected_to game_tables_path
    assert_not @game_table.participations.exists?(user: @player)
  end

  test "an invitation to a draft cannot be answered yet" do
    @game_table.update!(status: GameTable::DRAFT_STATUS)
    invite_player
    sign_in @player
    patch game_table_invitation_answer_path(@game_table)

    assert_response :not_found
  end

  test "only an invitation of my own, not answered yet, can be answered" do
    sign_in @game_master
    patch game_table_invitation_answer_path(@game_table)
    assert_response :not_found

    invite_player
    sign_in @player
    patch game_table_invitation_answer_path(@game_table)
    delete game_table_invitation_answer_path(@game_table)
    assert_response :not_found
    assert @game_table.participations.exists?(user: @player)
  end

  private

  def invite_player
    @game_table.participations.create!(user: @player, role: :player, status: :pending)
  end

  def cards_row_selector
    "main section[aria-labelledby=all-tables-title] ul"
  end
end
