require "test_helper"

# The template editor, the fields of the character sheet (SheetTemplates::FieldsController): the list by section, the
# form of a field with the settings its type asks, saved through the validator of the template. Only on a template of
# the game master
class SheetTemplateFieldsTest < ActionDispatch::IntegrationTest
  setup do
    @game_master = User.create!(email: "mj@example.com", username: "Morgane", password: TEST_PASSWORD, locale: "fr")
    @fantasy = EquipmentSpellsTemplateBuilder.create_template
    @template = SheetTemplates::Duplicator.new(original: @fantasy, owner: @game_master).call
    sign_in @game_master
  end

  test "the creation path shows the steps in their order, their sections and fields, no key shown" do
    get sheet_template_path(@template)
    assert_equal ["Informations", "Parcours de création", "Catalogue"], css_select("ol li > [title]").pluck("title")
    assert_select "a[href=?]", sheet_template_fields_path(@template), text: "Suivant"

    get sheet_template_fields_path(@template)
    assert_response :success
    assert_select "main h1", text: "Parcours de création"
    assert_select "ol li[aria-current=step]", text: /Parcours de création/
    assert_equal %w[Classe Équipement Sorts Description], css_select("main ol input[name=label]").pluck("value")
    assert_select "main", text: /Seulement si l'option choisie donne des sorts/
    assert_select "section h3", text: "Équipement"
    assert_select "a[href=?]", edit_sheet_template_field_path(@template, "level") do
      assert_select "span", text: "Niveau"
      assert_select "span", text: /Nombre · Donné par la table/
    end
    assert_select "a[href=?] span", edit_sheet_template_field_path(@template, "starting_gold"), text: /Calculé · Interne|Interne/
    assert_select "main", text: /Ajouter un champ · Bientôt/
    assert_select "main", text: /starting_gold|spellcasting/, count: 0
  end

  test "a step is renamed, the only change of a step; an empty name is refused" do
    patch sheet_template_creation_step_path(@template, "class"), params: { label: "Vocation" }
    assert_redirected_to sheet_template_fields_path(@template)
    assert_equal "Vocation", @template.reload.character_fields["creation_steps"].first["label"]

    patch sheet_template_creation_step_path(@template, "class"), params: { label: "" }
    assert_response :unprocessable_content
    assert_select "[role=alert] li", text: /le libellé doit être rempli/
    assert_select "main ol input[name=label][value=?]", "Vocation"
  end

  test "a template without steps shows its single page" do
    @template.update!(character_fields: @template.character_fields.except("creation_steps"))

    get sheet_template_fields_path(@template)
    assert_select "main h2", text: "Une seule page"
    assert_select "main ol input[name=label]", count: 0
  end

  test "the form asks the settings of the type, each by its kind, the key and the type never" do
    get edit_sheet_template_field_path(@template, "level")

    assert_response :success
    assert_select "main h1", text: "Niveau"
    assert_select "input[name='field[label]'][value=?]", "Niveau"
    assert_select "input[type=number][name='field[max]']"
    assert_select "select[name='field[section]'] option[selected][value=?]", "Notes"
    assert_select "select[name='field[from_table]'] option[selected]", text: "Niveau de départ de la table"
    assert_select "select[name='field[initial_from]'] option[value=?]", "starting_gold", text: "Or de départ"
    assert_select "select[name='field[initial_from]'] option[value='']", text: "Aucune"
    assert_select "button[aria-controls='parameter-max-help'][aria-label=?][hidden]", "Aide\u00A0: Maximum"
    assert_select "input[name='field[max]'][aria-describedby='parameter-max-help']"
    assert_select "main", text: /level\b/, count: 0
    assert_select "input[type=checkbox][name='field[at_creation]'][checked]"
    assert_select "[name='field[key]'], [name='field[type]']", count: 0
  end

  test "the options of a list with effects are not offered, and the page says why" do
    get edit_sheet_template_field_path(@template, "class")

    assert_select "[name='field[options]']", count: 0
    assert_select "p", text: /Les effets et les descriptions des options se modifieront bientôt/
  end

  test "saving changes the field and goes back to the list" do
    patch sheet_template_field_path(@template, "level"),
          params: { field: { label: "Rang", section: "Notes", from_table: "starting_level", max: "12",
                             at_creation: "1" } }

    assert_redirected_to sheet_template_fields_path(@template)
    level = @template.reload.character_fields["fields"].find { |field| field["key"] == "level" }
    assert_equal ["Rang", 12], level.values_at("label", "max")
  end

  test "a refused value shows the errors of the template and keeps what was typed" do
    patch sheet_template_field_path(@template, "level"),
          params: { field: { label: "Rang", section: "Notes", min: "10", max: "5", at_creation: "1" } }

    assert_response :unprocessable_content
    assert_select "[role=alert] li", text: /le minimum \(10\) dépasse le maximum \(5\)/
    assert_select "input[name='field[min]'][value='10']"
    assert_select "main h1", text: "Niveau"
  end

  test "a field opens its form in a window over the path, without the band of the editor" do
    get sheet_template_fields_path(@template)
    assert_select "dialog#field-dialog turbo-frame#field_dialog"
    assert_select "a[href=?][data-turbo-frame=field_dialog]", edit_sheet_template_field_path(@template, "level")

    get edit_sheet_template_field_path(@template, "level"), headers: { "Turbo-Frame" => "field_dialog" }
    assert_response :success
    assert_select "turbo-frame#field_dialog h2#field-dialog-title", text: "Niveau"
    assert_select "turbo-frame#field_dialog button[data-action='frame-dialog#close']", minimum: 2
    assert_select "ol li[aria-current=step]", count: 0
    assert_includes response.headers["Vary"], "Turbo-Frame"
  end

  test "saved from the window, the page behind is refreshed; refused, the errors stay in the window" do
    patch sheet_template_field_path(@template, "level"), headers: { "Turbo-Frame" => "field_dialog" },
                                                         params: { field: { label: "Rang", section: "Notes", at_creation: "1" } }
    assert_response :success
    assert_select "turbo-stream[action=refresh]:not([request-id])"
    assert_equal "Rang", @template.reload.character_fields["fields"].find { |field| field["key"] == "level" }["label"]

    patch sheet_template_field_path(@template, "level"), headers: { "Turbo-Frame" => "field_dialog" },
                                                         params: { field: { label: "Rang", section: "Notes", min: "10", max: "5", at_creation: "1" } }
    assert_response :unprocessable_content
    assert_select "turbo-frame#field_dialog [role=alert] li", text: /le minimum \(10\) dépasse le maximum \(5\)/
  end

  test "only the owner edits a template, and only a field it has" do
    others_template = SheetTemplates::Duplicator.new(
      original: @fantasy, owner: User.create!(email: "b@example.com", username: "Basile", password: TEST_PASSWORD)
    ).call

    [others_template, @fantasy].each do |sheet_template|
      assert_not_found { get sheet_template_fields_path(sheet_template) }
      assert_not_found { get edit_sheet_template_field_path(sheet_template, "level") }
      assert_not_found { patch sheet_template_field_path(sheet_template, "level"), params: { field: { label: "X" } } }
      assert_not_found { patch sheet_template_creation_step_path(sheet_template, "class"), params: { label: "X" } }
    end
    assert_not_found { get edit_sheet_template_field_path(@template, "unknown") }
    assert_not_found { patch sheet_template_creation_step_path(@template, "unknown"), params: { label: "X" } }
    assert_equal "Niveau", others_template.reload.character_fields["fields"].find { |f| f["key"] == "level" }["label"]
  end

  private

  # A 404 does not save the session: the next request signs in again (sign_in only signs in the next one)
  def assert_not_found
    yield
    assert_response :not_found
    sign_in @game_master
  end
end
