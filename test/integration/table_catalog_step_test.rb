require "test_helper"

# The third step of a table: the spells and items of the catalog of its template it offers
class TableCatalogStepTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    @game_table = GameTableCreator.new(user: @user, attributes: { name: "La Crypte" },
                                       sheet_template: sheet_template).call
    @game_table.reach_creation_step("catalog")
    sign_in @user
  end

  test "the spells tab shows every spell of the template by level, all offered" do
    get edit_game_table_catalog_path(@game_table)

    assert_response :success
    assert_select "ol[aria-label] > li[aria-current=step]", text: /Sorts et objets/
    assert_select "button[name=go_to][value=spell][aria-pressed=true]", text: "Sorts"
    assert_select "h2", text: "Sorts mineurs"
    assert_select "h2", text: "Niveau 1"
    assert_select "input[type=checkbox][role=switch][name='offered_keys[]'][checked]", count: 7
    assert_select "label[for=offered-spell-shield]", text: "Bouclier"
    assert_select "p", text: "7 proposés sur 7"
    assert_select "p", text: /Les personnages déjà créés gardent leur version/
  end

  test "continue saves the spells left out and opens the summary" do
    patch game_table_catalog_path(@game_table, kind: "spell"),
          params: { offered_keys: ["", "fire-bolt", "light", "mage-hand", "magic-missile", "bless", "blur"] }

    assert_redirected_to game_table_summary_path(@game_table)
    assert_equal({ "spell" => ["shield"] }, @game_table.reload.disabled_catalog_keys)
    assert_equal "summary", @game_table.resume_creation_step
  end

  test "changing tab saves the tab shown first" do
    patch game_table_catalog_path(@game_table, kind: "spell"), params: { offered_keys: [""], go_to: "item" }

    assert_redirected_to edit_game_table_catalog_path(@game_table, kind: "item")
    assert_equal 7, @game_table.reload.disabled_catalog_keys["spell"].size
    assert_equal "catalog", @game_table.resume_creation_step
  end

  test "an item of the starting equipment stays offered, its switch disabled" do
    get edit_game_table_catalog_path(@game_table, kind: "item")

    assert_select "h2", text: "Arme"
    assert_select "input#offered-item-dagger[disabled][checked]"
    assert_select "p#offered-item-dagger-detail", text: "Fait partie de l'équipement de départ"
    patch game_table_catalog_path(@game_table, kind: "item"), params: { offered_keys: [""] }
    assert_equal %w[flute lute], @game_table.reload.disabled_catalog_keys["item"]
  end

  test "on a table ready, save shows the same tab again" do
    @game_table.finish_creation!
    patch game_table_catalog_path(@game_table, kind: "item"), params: { offered_keys: ["", "lute", "flute"] }

    assert_redirected_to edit_game_table_catalog_path(@game_table, kind: "item")
    assert_equal "Sorts et objets enregistrés.", flash[:notice]
  end

  test "only the game master of the table reaches its spells and items" do
    sign_in User.create!(email: "other@example.com", username: "other", password: TEST_PASSWORD)
    get edit_game_table_catalog_path(@game_table)

    assert_response :not_found
  end
end
