require "test_helper"

# A spell or an item of the catalog of a table, in its window: seen, changed for the table (its copy), restored,
# added from an empty window, deleted
class TableCatalogEntriesTest < ActionDispatch::IntegrationTest
  FRAME_HEADERS = { "Turbo-Frame" => GameTables::CatalogEntryDialogHelper::FRAME }.freeze

  setup do
    @user = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
    @sheet_template = EquipmentSpellsTemplateBuilder.create_template
    @game_table = GameTableCreator.new(user: @user, attributes: { name: "La Crypte" },
                                       sheet_template: @sheet_template).call
    sign_in @user
  end

  test "the window of a spell shows every value its template declares, in the fields of a sheet" do
    get edit_game_table_catalog_entry_path(@game_table, "magic-missile", kind: "spell"), headers: FRAME_HEADERS

    assert_response :success
    assert_select "turbo-frame#catalog_entry_dialog" do
      assert_select "h2#catalog-entry-dialog-title", text: "Projectile magique"
      assert_select "input[name='catalog_entry[name]'][value=?]", "Projectile magique"
      assert_select "input[type=number][name='catalog_entry[properties][level]'][value='1']"
      assert_select "select[name='catalog_entry[properties][school]']"
      assert_select "input[type=checkbox][name='catalog_entry[properties][classes][]'][value=Mage][checked]"
      assert_select "textarea[name='catalog_entry[description]']"
      assert_select "button", text: "Rétablir l'original", count: 0
    end
  end

  test "the window groups the values by the sections of the template, the level of a spell in a list of names" do
    fields = [
      { "key" => "level", "label" => "Niveau", "section" => "Niveau et école", "type" => "number", "min" => 0,
        "max" => 2, "labels" => ["Sort mineur", "Niveau 1", "Niveau 2"], "required" => true },
      { "key" => "school", "label" => "École", "section" => "Niveau et école", "type" => "choice",
        "options" => ["Évocation"] },
      { "key" => "classes", "label" => "Classes", "section" => "Classes", "type" => "picks",
        "options" => %w[Mage Prêtre], "required" => true }
    ]
    # The window reads the template the table was made from, not its copy (a table made before the sections has them)
    @sheet_template.update!(spell_fields: { "fields" => fields })
    get edit_game_table_catalog_entry_path(@game_table, "magic-missile", kind: "spell"), headers: FRAME_HEADERS

    assert_equal ["Niveau et école", "Classes"], css_select("section h3").map(&:text)
    assert_nil @game_table.reload.template_snapshot.dig("spell_fields", "fields").first["section"]
    assert_select "select[name='catalog_entry[properties][level]']" do
      assert_select "option[value='0']", text: "Sort mineur"
      assert_select "option[value='1'][selected]", text: "Niveau 1"
    end
    patch game_table_catalog_entry_path(@game_table, "magic-missile", kind: "spell"),
          params: { catalog_entry: { name: "Projectile magique", properties: { level: "2", classes: ["", "Mage"] } } }
    assert_equal 2, @game_table.catalog_entries.find_by!(key: "magic-missile").level
  end

  test "changing a spell of the template makes the table's copy, the template keeps the original" do
    patch game_table_catalog_entry_path(@game_table, "magic-missile", kind: "spell"),
          params: { catalog_entry: { name: "Projectile mystique", description: "Trois fléchettes.",
                                     properties: { level: "2", school: "Évocation", classes: ["", "Mage"] } } }

    assert_redirected_to edit_game_table_catalog_path(@game_table, kind: "spell")
    copy = @game_table.catalog_entries.find_by!(kind: "spell", key: "magic-missile")
    assert_equal ["Projectile mystique", 2, ["Mage"]], [copy.name, copy.level, copy.properties["classes"]]
    assert_equal "Projectile magique", @sheet_template.catalog_entries.find_by!(key: "magic-missile").name
    get edit_game_table_catalog_path(@game_table)
    assert_select "span", text: "Modifié"
  end

  test "a value refused stays in the window with its error, nothing saved" do
    patch game_table_catalog_entry_path(@game_table, "magic-missile", kind: "spell"),
          params: { catalog_entry: { name: "Projectile magique", properties: { level: "12", classes: ["", "Mage"] } } },
          headers: FRAME_HEADERS

    assert_response :unprocessable_content
    assert_select "input[name='catalog_entry[properties][level]'][aria-invalid=true][value='12']"
    assert_not @game_table.catalog_entries.exists?
  end

  test "restoring the original deletes the table's copy" do
    @game_table.catalog_entries.create!(kind: "spell", key: "magic-missile", name: "Projectile mystique",
                                        properties: { "level" => 1, "classes" => ["Mage"] })
    get edit_game_table_catalog_entry_path(@game_table, "magic-missile", kind: "spell"), headers: FRAME_HEADERS
    assert_select "button[form=catalog-entry-removal]", text: "Rétablir l'original"

    delete game_table_catalog_entry_path(@game_table, "magic-missile", kind: "spell")
    assert_not @game_table.catalog_entries.exists?
  end

  test "an item is added from an empty window, belongs to the table, and can be deleted" do
    get new_game_table_catalog_entry_path(@game_table, kind: "item"), headers: FRAME_HEADERS
    assert_select "h2#catalog-entry-dialog-title", text: "Nouvel objet"
    assert_select "input[name='catalog_entry[name]']:not([value])"

    post game_table_catalog_entries_path(@game_table, kind: "item"),
         params: { catalog_entry: { name: "Épée de l'aube", properties: { category: "Arme" } } }
    added = @game_table.catalog_entries.find_by!(kind: "item")
    assert_equal ["epee-de-l-aube", "Arme"], [added.key, added.properties["category"]]
    assert_includes Catalogs::TableCatalog.new(@game_table).entries("item").pluck(:key), added.key
    get edit_game_table_catalog_path(@game_table, kind: "item")
    assert_select "span", text: "Ajouté"

    delete game_table_catalog_entry_path(@game_table, added.key, kind: "item")
    assert_not @game_table.catalog_entries.exists?(key: added.key)
  end

  test "an entry saved in the window refreshes the list behind" do
    post game_table_catalog_entries_path(@game_table, kind: "item"),
         params: { catalog_entry: { name: "Corde", properties: { category: "Arme" } } }, headers: FRAME_HEADERS

    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_match "refresh", response.body
  end

  test "only the game master of the table sees and changes its catalog" do
    sign_in User.create!(email: "other@example.com", username: "other", password: TEST_PASSWORD)
    get edit_game_table_catalog_entry_path(@game_table, "magic-missile", kind: "spell")

    assert_response :not_found
  end
end
