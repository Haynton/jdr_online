require "test_helper"

# First step of the creation of a table: name, description, cover and sheet template (GameTablesController#new and
# #create), then the same step for a draft taken up again (GameTables::DetailsController)
class TableCreationTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
    @fantasy = SheetTemplate.create!(name: "Fantasy héroïque", locale: "fr", character_fields: { "fields" => [] })
    @horror = SheetTemplate.create!(name: "Horreur cosmique", locale: "fr", character_fields: { "fields" => [] })
    sign_in @user
  end

  test "the first step shows the five steps, the covers and the templates of the user's language, none chosen" do
    SheetTemplate.create!(name: "Heroic fantasy", locale: "en")
    get new_game_table_path

    assert_response :success
    # The lines that join the steps are list items too, hidden from screen readers
    assert_select "ol[aria-label=?] > li:not([aria-hidden])", "Étapes de la création", count: 5
    assert_select "ol > li[aria-current=step]", text: /Informations/
    assert_select "ol > li", text: /Bientôt/, count: 2
    assert_select "input[type=radio][name='game_table[cover_image]']", count: GameTable::COVER_IMAGES.size
    assert_select "input[type=radio][name='game_table[sheet_template_id]']", count: 2
    assert_select "input[type=radio][name='game_table[sheet_template_id]'][checked]", count: 0
    assert_select "label", text: "Heroic fantasy", count: 0
  end

  test "cancel then continue close the form, on its last line" do
    get new_game_table_path

    assert_select "form#game-table-creation-form > div:last-child" do
      assert_select "a[href=?]", game_tables_path, text: "Annuler"
      assert_select "a + button[type=submit][form=?]", "game-table-creation-form", text: "Continuer"
    end
  end

  test "the row of templates starts with the card that leads to the templates of the game master" do
    get new_game_table_path

    assert_select "fieldset ul li:first-child a[href=?]", sheet_templates_path, text: /Créer un modèle/
    get sheet_templates_path

    assert_response :success
    assert_select "main h1", text: "Mes modèles"
  end

  test "the covers can be filtered by theme with pills, hidden until the filter controller shows them" do
    get new_game_table_path

    assert_select "fieldset[data-controller='card-row table-filter']" do
      assert_select "div[hidden][role=group][aria-label=?] button[aria-pressed=false][data-group=theme]",
                    "Filtrer par thème", count: GameTable::COVER_THEME_NAMES.size
      assert_select "button[data-value=horror]", text: "Horreur"
      assert_select "li[data-table-filter-target=card][data-theme=fantasy] input[value=dragon]"
      assert_select "li[hidden][data-table-filter-target=noMatch]", text: /Aucune couverture pour ce thème/
    end
  end

  test "the description is a text area that is not held to the height of the other fields" do
    get new_game_table_path

    assert_select "textarea#game_table_description.min-h-24"
    assert_select "textarea#game_table_description.h-10", count: 0
  end

  test "creating a table makes a draft with a copy of its template, and its creator its game master" do
    assert_difference(["GameTable.count", "Participation.count"], 1) { post_new_table(sheet_template_id: @fantasy.id) }

    game_table = GameTable.last
    assert_redirected_to edit_game_table_settings_path(game_table)
    # For screen readers only: on screen, the next step shows
    assert_equal "Table créée en brouillon. Vous pouvez reprendre sa création à tout moment.", flash[:screen_reader_notice]
    assert_nil flash[:notice]
    follow_redirect!
    assert_select ".sr-only [role=status]", text: /Table créée en brouillon/
    assert_equal "settings", game_table.reload.resume_creation_step
    assert game_table.draft?
    assert_equal "dragon", game_table.cover_image
    assert_equal @fantasy, game_table.sheet_template
    assert_equal @fantasy.snapshot, game_table.template_snapshot
    assert game_table.participations.find_by(user: @user).game_master?
  end

  test "without a template, nothing is saved and the template choice says why" do
    assert_no_difference("GameTable.count") { post_new_table(sheet_template_id: "") }

    assert_response :unprocessable_content
    invalid_template_choice = "input[name='game_table[sheet_template_id]'][aria-invalid=true]"
    assert_select "#{invalid_template_choice}[aria-describedby=sheet-template-error]", count: 2
    assert_select "#sheet-template-error", text: /choisissez un modèle de fiche/
  end

  test "the template of another game master cannot be chosen, even by its id" do
    other_user = User.create!(email: "other@example.com", username: "other", password: TEST_PASSWORD)
    someone_elses_template = SheetTemplate.create!(name: "Son jeu", owner: other_user)

    assert_no_difference("GameTable.count") { post_new_table(sheet_template_id: someone_elses_template.id) }
    assert_response :unprocessable_content
  end

  test "a cover outside the images of the app is refused" do
    assert_no_difference("GameTable.count") { post_new_table(sheet_template_id: @fantasy.id, cover_image: "../secret") }
    assert_response :unprocessable_content
  end

  test "the game master of a draft takes up its first step again, with its values" do
    game_table = create_draft_table

    get edit_game_table_details_path(game_table)

    assert_response :success
    assert_select "input#game_table_name[value=?]", "Les Marches du Nord"
    assert_select "input[name='game_table[sheet_template_id]'][value='#{@fantasy.id}'][checked]"
  end

  test "changing the template of a draft copies the new one into the table" do
    game_table = create_draft_table

    patch game_table_details_path(game_table),
          params: { game_table: { name: "Les Marches du Nord", cover_image: "wolf", sheet_template_id: @horror.id } }

    assert_redirected_to edit_game_table_settings_path(game_table)
    assert_equal @horror.snapshot, game_table.reload.template_snapshot
    assert_equal "wolf", game_table.cover_image
  end

  test "a player cannot open the creation of a table, even by its address" do
    game_master = User.create!(email: "master@example.com", username: "master", password: TEST_PASSWORD)
    game_table = create_draft_table(game_master: game_master)
    game_table.participations.create!(user: @user, role: :player)

    get edit_game_table_details_path(game_table)

    assert_response :not_found
  end

  test "once the table is ready, its first step shows its template without choosing, and saves on the same page" do
    game_table = create_draft_table
    game_table.update!(status: "ready")
    get edit_game_table_details_path(game_table)

    assert_select "main h1", text: "Paramètres de la partie"
    assert_select "input[name='game_table[sheet_template_id]']", count: 0
    assert_select "section[aria-labelledby=frozen-sheet-template-title]", text: /Fantasy héroïque/
    assert_select "button[type=submit][form=game-table-creation-form]", text: "Enregistrer"
    patch game_table_details_path(game_table),
          params: { game_table: { name: "Les Marches du Sud", cover_image: "wolf", sheet_template_id: @horror.id } }
    assert_redirected_to edit_game_table_details_path(game_table)
    assert_equal "Les Marches du Sud", game_table.reload.name
    assert_equal @fantasy, game_table.sheet_template
  end

  private

  def post_new_table(sheet_template_id:, cover_image: "dragon")
    post game_tables_path, params: {
      game_table: { name: "L'Ombre du Dragon", description: "Un dragon s'éveille.", cover_image: cover_image,
                    sheet_template_id: sheet_template_id }
    }
  end

  def create_draft_table(game_master: @user)
    GameTableCreator.new(user: game_master, attributes: { name: "Les Marches du Nord" }, sheet_template: @fantasy).call
  end
end
