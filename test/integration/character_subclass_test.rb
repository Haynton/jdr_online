require "test_helper"

# The subclass of a character (2024 rules: chosen at level 3): a list that offers the subclasses of the class picked,
# asked only from level 3, taken out when the class changes, and the spells it always prepares
class CharacterSubclassTest < ActionDispatch::IntegrationTest
  SUBCLASS = {
    "key" => "subclass", "label" => "Sous-classe", "type" => "choice", "section" => "Classe", "required" => true,
    "options" => ["Domaine de la Vie", "Évocateur"], "options_from" => "class", "from_level" => 3,
    "level_from" => "level", "options_by" => { "Prêtre" => ["Domaine de la Vie"], "Mage" => ["Évocateur"] },
    "descriptions" => { "Domaine de la Vie" => "Un guérisseur.", "Évocateur" => "Un maître du feu." },
    "effects" => {
      "Domaine de la Vie" => { "always_prepared_spells" => { "3" => ["shield"], "5" => ["blur"] },
                               "features_by_level" => { "3" => [{ "key" => "disciple", "name" => "Disciple de la vie" }],
                                                        "6" => [{ "key" => "healer", "name" => "Guérisseur béni" }] } }
    }
  }.freeze

  setup do
    game_master = User.create!(email: "julien@example.com", username: "Julien", password: TEST_PASSWORD)
    @player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template(extra_fields: [SUBCLASS])
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, sheet_template: sheet_template,
                                    template_snapshot: sheet_template.snapshot, starting_level: 3)
    @game_table.participations.create!(user: game_master, role: :game_master)
    @game_table.participations.create!(user: @player, role: :player)
    sign_in @player
  end

  test "from level 3, the list offers the subclass of the class picked, and its features reached" do
    save_class_step(class: "Prêtre")

    assert_response :unprocessable_content
    assert_select "[data-controller=dependent-choice]:not([hidden]) select#character_sheet_subclass" do
      assert_select "option[value=?]", "Domaine de la Vie"
      assert_select "option[value=?]", "Évocateur", count: 0
    end
    assert_select "li:not([hidden])", text: /Disciple de la vie\s+Niveau 3/
    assert_select "li[hidden]", text: /Guérisseur béni\s+Niveau 6/
  end

  test "the subclass is required from level 3, and one of another class is refused" do
    save_class_step(class: "Prêtre")
    assert_response :unprocessable_content

    save_class_step(class: "Prêtre", subclass: "Évocateur")
    assert_response :unprocessable_content
    assert_nil character

    save_class_step(class: "Prêtre", subclass: "Domaine de la Vie")
    assert_equal "Domaine de la Vie", character.sheet["subclass"]
  end

  test "under level 3, the list is hidden, nothing is asked and a subclass sent is taken out" do
    @game_table.update!(starting_level: 1)
    save_class_step(class: "Prêtre", subclass: "Domaine de la Vie")
    assert_nil character.sheet["subclass"]

    get class_step_path
    assert_select "[data-controller=dependent-choice][hidden] select#character_sheet_subclass"
  end

  test "changing the class takes the subclass out, with the spells it always prepared" do
    save_class_step(class: "Prêtre", subclass: "Domaine de la Vie")
    patch game_table_character_step_path(@game_table, "equipment"), params: { character: { sheet: {} } }
    assert_includes character.spells.pluck("key"), "shield"

    # A warrior has no subclass in this small template: nothing is asked
    save_class_step(class: "Guerrier", subclass: "Domaine de la Vie")
    assert_nil character.sheet["subclass"]
    assert_empty character.spells
  end

  test "the spells the subclass always prepares are ticked apart, counted in no group, and on the summary" do
    save_class_step(class: "Prêtre", subclass: "Domaine de la Vie")
    patch game_table_character_step_path(@game_table, "equipment"), params: { character: { sheet: {} } }
    get spells_step_path

    assert_select "h2", text: "Sorts toujours préparés"
    assert_select "p", text: /Donnés par Domaine de la Vie/
    assert_select "input[type=checkbox][value=shield][disabled][checked]:not([name])"
    assert_select "input[name=?][value=shield]", "character[spell_keys][]", count: 0

    patch spells_step_path, params: { character: { spell_keys: %w[light bless] } }
    assert_redirected_to game_table_character_step_path(@game_table, "description")
    assert_equal [["bless", nil], ["light", nil], ["shield", true]],
                 character.spells.map { |spell| spell.values_at("key", "always_prepared") }.sort

    patch game_table_character_step_path(@game_table, "description"), params: { character: { name: "Elara" } }
    follow_redirect!
    assert_select "h3", text: "Sorts toujours préparés"
    assert_select "dd", text: "Domaine de la Vie"
  end

  private

  def save_class_step(**sheet)
    patch class_step_path, params: { character: { sheet: sheet } }
  end

  def class_step_path
    game_table_character_step_path(@game_table, "class")
  end

  def spells_step_path
    game_table_character_step_path(@game_table, "spells")
  end

  # nil while no step was saved
  def character
    @player.participations.find_by!(game_table: @game_table).reload.character
  end
end
