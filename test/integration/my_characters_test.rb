require "test_helper"

# « Mes personnages »: the characters of a player on all their tables, the sheet of one of them, and its identity and
# description changed once it is complete (never its class). Only the player's own characters
class MyCharactersTest < ActionDispatch::IntegrationTest
  setup do
    game_master = User.create!(email: "julien@example.com", username: "Julien", password: TEST_PASSWORD)
    @player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, sheet_template: sheet_template,
                                    template_snapshot: sheet_template.snapshot)
    @game_table.participations.create!(user: game_master, role: :game_master)
    participation = @game_table.participations.create!(user: @player, role: :player)
    @character = participation.create_character!(game_table: @game_table, kind: :pc, status: :complete, name: "Aria",
                                                 sheet: { "class" => "Mage", "notes" => "Née sous la lune." })
    sign_in @player
  end

  test "the navigation leads to the characters, right after the tables" do
    get characters_path

    links = css_select("#side-nav a").pluck("href")
    assert_equal characters_path, links[links.rindex(game_tables_path) + 1]
    assert_select "#side-nav a[href=?][aria-current=page]", characters_path
  end

  test "the list shows each character with its class and its table" do
    get characters_path

    assert_select "main h1", text: "Mes personnages"
    assert_select "a[href=?]", character_path(@character) do
      assert_select "span", text: "Aria"
      assert_select "span", text: "Mage"
      assert_select "span", text: "Table « La Crypte »"
    end
  end

  test "a draft says so and leads back to its creation steps" do
    @character.update!(status: :draft)
    get characters_path

    assert_select "a[href=?]", new_game_table_character_path(@game_table) do
      assert_select "span", text: "Brouillon"
      assert_select "span", text: "Reprendre mon personnage"
    end

    get character_path(@character)
    assert_redirected_to new_game_table_character_path(@game_table)
  end

  test "with no character, a card says how to make one" do
    @character.destroy!
    get characters_path

    assert_select "a[href=?]", game_tables_path, text: /Aucun personnage pour l'instant/
  end

  test "the sheet is read only: its name as the title, Change for its description only" do
    get character_path(@character)

    assert_select "main h1", text: "Aria"
    assert_select "a[href=?]", edit_character_path(@character), text: /Modifier/
    assert_select "a[href^=?]", "/game_tables/#{@game_table.id}/character/steps", count: 0
    assert_select "form[action=?]", game_table_character_step_path(@game_table, CharacterCreationSteps::SUMMARY),
                  count: 0
  end

  test "the sheet shows what the character carries and its spells, each description on demand" do
    @character.update!(sheet: @character.sheet.merge("gold" => 7),
                       spells: [{ "key" => "light", "name" => "Lumière", "level" => 0,
                                  "description" => "Un objet brille.", "properties" => { "school" => "Évocation" } }])
    @character.inventory_items.create!(key: "dagger", name: "Dague", quantity: 2, description: "Une lame courte.",
                                       properties: { "damage" => "1d4 perforants" })
    get character_path(@character)

    assert_select "h3", text: "Inventaire"
    assert_select "details summary", text: /2 × Dague\s+1d4 perforants/
    assert_select "details p", text: "Une lame courte."
    assert_select "li", text: "Pièces d'or\u00a0: 7"
    assert_select "details summary", text: /Lumière\s+Évocation/
    assert_select "details p", text: "Un objet brille."
    assert_select "button[hidden][aria-haspopup=dialog][data-details-dialog-name-param=Lumière]" \
                  "[data-details-dialog-summary-param=Évocation]", text: /Lumière\s+Évocation/
    assert_select "button[data-details-dialog-name-param=Dague][data-details-dialog-summary-param='1d4 perforants']"
  end

  test "the form asks the name and the description, never the class" do
    get edit_character_path(@character)

    assert_select "input[name=?][value=Aria]", "character[name]"
    assert_select "textarea[name=?]", "character[sheet][notes]", text: "Née sous la lune."
    assert_select "[name=?]", "character[sheet][class]", count: 0
  end

  test "saving changes the name and the description, and nothing else" do
    patch character_path(@character), params: { character: { name: "Aria la Brave", sheet: {
      notes: "Revenue de la crypte.", class: "Guerrier"
    } } }

    assert_redirected_to character_path(@character)
    @character.reload
    assert_equal "Aria la Brave", @character.name
    assert_equal({ "class" => "Mage", "notes" => "Revenue de la crypte." }, @character.sheet)
  end

  test "a complete character keeps its name" do
    patch character_path(@character), params: { character: { name: "", sheet: { notes: "" } } }

    assert_response :unprocessable_content
    assert_equal "Aria", @character.reload.name
  end

  test "the character of another player is not found" do
    other_player = User.create!(email: "other@example.com", username: "other", password: TEST_PASSWORD)
    sign_in other_player

    get characters_path
    assert_select "a[href=?]", character_path(@character), count: 0
    [-> { get character_path(@character) }, -> { get edit_character_path(@character) },
     -> { patch character_path(@character), params: { character: { name: "À moi" } } }].each do |request|
      request.call
      assert_response :not_found
      sign_in other_player
    end
    assert_equal "Aria", @character.reload.name
  end
end
