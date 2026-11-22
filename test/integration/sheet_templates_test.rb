require "test_helper"

# "My templates" (SheetTemplatesController) and "Duplicate" (SheetTemplates::DuplicatesController): a game master
# makes their template from another one, renames it, deletes it while no table uses it. Every permission is checked by
# the server: only their own templates, and only the templates they may pick to duplicate
class SheetTemplatesTest < ActionDispatch::IntegrationTest
  setup do
    @game_master = User.create!(email: "mj@example.com", username: "Morgane", password: TEST_PASSWORD, locale: "fr")
    @other_game_master = User.create!(email: "autre@example.com", username: "Basile", password: TEST_PASSWORD)
    @fantasy = EquipmentSpellsTemplateBuilder.create_template
    sign_in @game_master
  end

  test "the list shows the predefined templates of the language of the page, to duplicate, and none of mine yet" do
    SheetTemplate.create!(name: "Heroic fantasy", locale: "en")
    get sheet_templates_path

    assert_response :success
    assert_select "main h1", text: "Mes modèles"
    assert_select "p", text: /Aucun modèle pour l'instant/
    assert_select "li", text: /Fantasy/, count: 1
    assert_select "form[action=?] button[aria-label=?]", sheet_template_duplicate_path(@fantasy), "Dupliquer Fantasy"
    assert_select "li", text: /Heroic fantasy/, count: 0
    assert_select "#side-nav a[href=?][aria-current=page]", sheet_templates_path, text: /Mes modèles/
  end

  test "duplicating makes a template of mine with the catalog of the original, then opens its page" do
    assert_difference -> { @game_master.sheet_templates.count } => 1, -> { CatalogEntry.count } => 11 do
      post sheet_template_duplicate_path(@fantasy)
    end

    copy = @game_master.sheet_templates.last
    assert_redirected_to sheet_template_path(copy)
    follow_redirect!
    assert_select "main h1", text: "Fantasy (copie)"
    assert_select "header p", text: /\AD'après «[[:space:]]Fantasy[[:space:]]»\z/
    assert_select "#sheet_template_name[value=?]", "Fantasy (copie)"
    assert_select "p", text: "7 sorts et 4 objets"
    assert_select "#side-nav a[aria-current=page]", text: /Mes modèles/
    get sheet_templates_path
    assert_select "a[href=?]", sheet_template_path(copy), text: /Fantasy \(copie\)/
  end

  test "the template of another game master cannot be duplicated, my own one can" do
    others_template = SheetTemplates::Duplicator.new(original: @fantasy, owner: @other_game_master).call
    mine = SheetTemplates::Duplicator.new(original: @fantasy, owner: @game_master).call

    post sheet_template_duplicate_path(others_template)
    assert_response :not_found
    sign_in @game_master
    assert_difference -> { @game_master.sheet_templates.count } => 1 do
      post sheet_template_duplicate_path(mine)
    end
  end

  test "a template of mine is renamed; a blank name is refused and the title keeps the saved name" do
    mine = SheetTemplates::Duplicator.new(original: @fantasy, owner: @game_master).call

    patch sheet_template_path(mine), params: { sheet_template: { name: "Mes Royaumes" } }
    assert_redirected_to sheet_template_path(mine)
    assert_equal "Mes Royaumes", mine.reload.name

    patch sheet_template_path(mine), params: { sheet_template: { name: "" } }
    assert_response :unprocessable_content
    assert_select "main h1", text: "Mes Royaumes"
    assert_select "#sheet_template_name[aria-invalid=true]"
  end

  test "only the owner sees, renames or deletes a template, never a predefined one" do
    others_template = SheetTemplates::Duplicator.new(original: @fantasy, owner: @other_game_master).call

    [others_template, @fantasy].each do |sheet_template|
      assert_not_found { get sheet_template_path(sheet_template) }
      assert_not_found { patch sheet_template_path(sheet_template), params: { sheet_template: { name: "Volé" } } }
      assert_not_found { delete sheet_template_path(sheet_template) }
    end
    assert_equal "Fantasy (copy)", others_template.reload.name
  end

  test "a template no table uses is deleted with its catalog" do
    mine = SheetTemplates::Duplicator.new(original: @fantasy, owner: @game_master).call
    get sheet_template_path(mine)
    assert_select "form[action=?] button[data-confirm-variant=danger]", sheet_template_path(mine)

    assert_difference -> { CatalogEntry.count } => -11 do
      delete sheet_template_path(mine)
    end
    assert_redirected_to sheet_templates_path
    assert_not SheetTemplate.exists?(mine.id)
  end

  test "a template a table uses is not deleted: its page says so instead of offering it" do
    mine = SheetTemplates::Duplicator.new(original: @fantasy, owner: @game_master).call
    GameTableCreator.new(user: @game_master, attributes: { name: "Les Marches" }, sheet_template: mine).call

    get sheet_template_path(mine)
    assert_select "p", text: /Utilisé par 1 table/
    assert_select "form[action=?][method=post] input[name=_method][value=delete]", sheet_template_path(mine), count: 0

    delete sheet_template_path(mine)
    assert_redirected_to sheet_template_path(mine)
    assert SheetTemplate.exists?(mine.id)
  end

  test "a visitor is sent to the sign in page" do
    sign_out @game_master

    get sheet_templates_path
    assert_redirected_to new_user_session_path
    post sheet_template_duplicate_path(@fantasy)
    assert_redirected_to new_user_session_path
  end

  private

  # A 404 does not save the session: the next request signs in again (sign_in only signs in the next one)
  def assert_not_found
    yield
    assert_response :not_found
    sign_in @game_master
  end
end
