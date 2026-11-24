require "test_helper"

# The third step of a table: every entry of the catalog of its template is offered, the step lists only what the
# game master customizes (picked in the whole catalog, changed, added, turned off)
class TableCatalogStepTest < ActionDispatch::IntegrationTest
  PICKER_HEADERS = { "Turbo-Frame" => GameTables::CatalogEntryDialogHelper::PICKER_FRAME }.freeze

  setup do
    @user = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    @game_table = GameTableCreator.new(user: @user, attributes: { name: "La Crypte" },
                                       sheet_template: sheet_template).call
    @game_table.reach_creation_step("catalog")
    sign_in @user
  end

  test "at first every spell is offered and the list of customizations is empty" do
    get edit_game_table_catalog_path(@game_table)

    assert_response :success
    assert_select "ol[aria-label] > li[aria-current=step]", text: /Sorts et objets/
    assert_select "a[aria-current=page]", text: "Sorts"
    assert_select "p", text: "7 sorts proposés, d'après le modèle."
    assert_select "p", text: /Tous les sorts et objets de votre modèle sont déjà proposés/
    assert_select "#catalog-customizations", text: /Aucun sort personnalisé/
    assert_select "a[href=?][data-turbo-frame=catalog_picker_dialog]",
                  game_table_catalog_picker_path(@game_table, kind: "spell"), text: /Personnaliser un sort/
    assert_select "a[href=?]", new_game_table_catalog_entry_path(@game_table, kind: "spell"), text: /Créer un sort/
  end

  test "the whole catalog lists every spell, each with Customize" do
    get game_table_catalog_picker_path(@game_table, kind: "spell"), headers: PICKER_HEADERS

    assert_select "turbo-frame#catalog_picker_dialog" do
      assert_select "h2", text: "Sorts du modèle"
      assert_select "h3", text: "Sorts mineurs"
      assert_select "button[title=?]", "Personnaliser Bouclier"
    end
  end

  test "a spell picked is copied for the table and listed, the window staying open" do
    post game_table_catalog_entries_path(@game_table, kind: "spell"), params: { from_key: "shield" },
                                                                      headers: PICKER_HEADERS

    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, %(target="catalog-customizations")
    assert_includes response.body, "Dans la liste : Bouclier."
    assert_equal ["shield"], @game_table.catalog_entries.pluck(:key)

    post game_table_catalog_entries_path(@game_table, kind: "spell"), params: { from_key: "shield" },
                                                                      headers: PICKER_HEADERS
    assert_equal 1, @game_table.catalog_entries.count
    get edit_game_table_catalog_path(@game_table)
    assert_select "#catalog-customizations li", count: 1, text: /Bouclier/
    assert_select "#catalog-customizations span", text: "Modifié", count: 0
    assert_select "input#offered-spell-shield[checked][aria-label=?]", "Bouclier dans la partie"
    assert_select "label[for=offered-spell-shield]", text: /Dans la partie\s*Retiré de la partie/
  end

  test "a switch turns one spell off, and on again" do
    patch game_table_catalog_entry_offer_path(@game_table, "shield", kind: "spell"), params: { offered: "0" }

    assert_redirected_to edit_game_table_catalog_path(@game_table, kind: "spell")
    assert_equal({ "spell" => ["shield"] }, @game_table.reload.disabled_catalog_keys)
    get edit_game_table_catalog_path(@game_table)
    assert_select "input#offered-spell-shield:not([checked])"

    patch game_table_catalog_entry_offer_path(@game_table, "shield", kind: "spell"), params: { offered: "1" }
    assert_equal({ "spell" => [] }, @game_table.reload.disabled_catalog_keys)
  end

  test "an item of the starting equipment can be taken out of it, and put back" do
    post game_table_catalog_entries_path(@game_table, kind: "item"), params: { from_key: "dagger" }
    get edit_game_table_catalog_path(@game_table, kind: "item")
    assert_select "input#offered-item-dagger[checked]:not([disabled])"
    assert_select "p#offered-item-dagger-detail", text: "Dans l'équipement de départ"

    patch game_table_catalog_entry_offer_path(@game_table, "dagger", kind: "item"), params: { offered: "0" }
    assert_equal ["dagger"], @game_table.reload.disabled_catalog_keys["item"]
    assert_not_includes Catalogs::TableCatalog.new(@game_table).entries("item").pluck(:key), "dagger"
    get edit_game_table_catalog_path(@game_table, kind: "item")
    assert_select "p#offered-item-dagger-detail", text: "Retiré de l'équipement de départ"
  end

  test "continue opens the NPCs and enemies" do
    patch game_table_catalog_path(@game_table)

    assert_redirected_to edit_game_table_cast_path(@game_table)
    assert_equal "npcs", @game_table.reload.resume_creation_step
  end

  test "only the game master of the table reaches its spells and items" do
    sign_in User.create!(email: "other@example.com", username: "other", password: TEST_PASSWORD)
    get edit_game_table_catalog_path(@game_table)

    assert_response :not_found
  end

  test "the changes are applied to the characters already made, after a question" do
    character = character_with_spell("shield")
    get edit_game_table_catalog_path(@game_table)
    assert_select "button", text: "Appliquer aux personnages déjà créés", count: 0

    shield = @game_table.sheet_template.catalog_entries.find_by!(kind: "spell", key: "shield")
    @game_table.catalog_entries.create!(kind: "spell", key: "shield", name: "Bouclier de givre",
                                        description: shield.description, properties: shield.properties)
    get edit_game_table_catalog_path(@game_table)
    assert_select "p", text: "1 personnage a une ancienne version d'un sort ou d'un objet que vous avez modifié."
    assert_select "form[data-turbo-confirm^=?] button", "Appliquer vos changements au personnage déjà créé ?",
                  text: "Appliquer aux personnages déjà créés"

    post game_table_catalog_application_path(@game_table, kind: "spell")
    assert_redirected_to edit_game_table_catalog_path(@game_table, kind: "spell")
    assert_equal "Changements appliqués à 1 personnage.", flash[:notice]
    assert_equal "Bouclier de givre", character.reload.spells.first["name"]
  end

  test "only the game master applies the changes" do
    other = User.create!(email: "other@example.com", username: "other", password: TEST_PASSWORD)
    sign_in other

    post game_table_catalog_application_path(@game_table)
    assert_response :not_found
  end

  private

  def character_with_spell(spell_key)
    player = User.create!(email: "lia@example.com", username: "lia_player", password: TEST_PASSWORD)
    participation = @game_table.participations.create!(user: player, role: "player")
    spell = @game_table.sheet_template.catalog_entries.find_by!(kind: "spell", key: spell_key)
    character = @game_table.characters.create!(kind: "pc", participation: participation, name: "Lia", status: "draft")
    character.update_columns(spells: [{ "key" => spell.key, "name" => spell.name, "level" => spell.level,
                                        "description" => spell.description, "properties" => spell.properties }])
    character
  end
end
