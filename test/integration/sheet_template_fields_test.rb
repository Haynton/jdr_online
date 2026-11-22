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
    assert_equal %w[Classe Équipement Sorts Description], css_select("main ol > li > div > h2").map(&:text)
    assert_select "main ol input", count: 0
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

  test "a template without steps shows its single page" do
    @template.update!(character_fields: @template.character_fields.except("creation_steps"))

    get sheet_template_fields_path(@template)
    assert_select "main h2", text: "Une seule page"
  end

  test "the form asks only what a game master tunes, its texts and its values, never what builds the sheet" do
    get edit_sheet_template_field_path(@template, "level")

    assert_response :success
    assert_select "main h1", text: "Niveau"
    assert_select "textarea[name='field[help]']"
    assert_select "input[type=number][name='field[max]']"
    assert_select "h2", text: "Textes"
    assert_select "h2", text: "Valeurs"
    assert_select "button[aria-controls='parameter-max-help'][aria-label=?][hidden]", "Aide\u00A0: Maximum"
    assert_select "input[name='field[max]'][aria-describedby='parameter-max-help']"
    assert_select "main", text: /level\b/, count: 0
    %w[label key type section column required at_creation visible_to_others summary_only internal from_table initial_from
       step abbreviation].each do |parameter|
      assert_select "[name='field[#{parameter}]']", count: 0
    end
  end

  test "a value worked out is said in a sentence that names the fields it reads" do
    get edit_sheet_template_field_path(@template, "starting_gold")
    assert_select "h2", text: "Calcul"
    assert_select "p", text: "L'or de l'équipement de départ choisi par le joueur."
    assert_select "[name='field[rule]']", count: 0

    get edit_sheet_template_field_path(@template, "intelligence")
    assert_select "p", text: /la valeur moins 10, divisée par 2/
    assert_select "[name='field[modifier]']", count: 0
  end

  test "the options of a list with effects are not offered, and the page says why" do
    get edit_sheet_template_field_path(@template, "class")

    assert_select "[name='field[options]']", count: 0
    assert_select "p", text: /Les effets et les descriptions des options se modifieront bientôt/
  end

  test "saving changes the field and goes back to the list; its label and what builds the sheet stay" do
    patch sheet_template_field_path(@template, "level"),
          params: { field: { label: "Rang", section: "Combat", from_table: "", max: "12", at_creation: "0" } }

    assert_redirected_to sheet_template_fields_path(@template)
    level = @template.reload.character_fields["fields"].find { |field| field["key"] == "level" }
    assert_equal ["Niveau", 12, "Notes", "starting_level"], level.values_at("label", "max", "section", "from_table")
    assert_not level.key?("at_creation")
  end

  test "a refused value shows the errors of the template and keeps what was typed" do
    patch sheet_template_field_path(@template, "level"),
          params: { field: { label: "Rang", min: "10", max: "5" } }

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
                                                         params: { field: { max: "12" } }
    assert_response :success
    assert_select "turbo-stream[action=refresh]:not([request-id])"
    assert_equal 12, @template.reload.character_fields["fields"].find { |field| field["key"] == "level" }["max"]

    patch sheet_template_field_path(@template, "level"), headers: { "Turbo-Frame" => "field_dialog" },
                                                         params: { field: { min: "10", max: "5" } }
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
    end
    assert_not_found { get edit_sheet_template_field_path(@template, "unknown") }
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
