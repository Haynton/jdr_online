require "test_helper"

class CharacterCreationTest < ActionDispatch::IntegrationTest
  SHEET_FIELDS = [
    { "key" => "class", "label" => "Classe", "type" => "choice", "section" => "Identité",
      "options" => %w[Mage Guerrier] },
    { "key" => "strength", "label" => "Force", "type" => "number", "section" => "Caractéristiques",
      "min" => 1, "max" => 20 },
    { "key" => "hp", "label" => "Points de vie", "type" => "resource", "section" => "Combat" },
    { "key" => "inspiration", "label" => "Inspiration", "type" => "boolean", "section" => "Combat" },
    { "key" => "background", "label" => "Histoire", "type" => "text", "section" => "Notes",
      "help" => "En quelques mots" }
  ].freeze

  setup do
    game_master = User.create!(email: "julien@example.com", username: "Julien", password: TEST_PASSWORD)
    @player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS,
                                    template_snapshot: { "character_fields" => { "fields" => SHEET_FIELDS } })
    @game_table.participations.create!(user: game_master, role: :game_master)
    @participation = @game_table.participations.create!(user: @player, role: :player)
  end

  test "the page shows the name, then the fields of the template by section" do
    sign_in @player
    get new_game_table_character_path(@game_table)

    assert_response :success
    assert_select "main h1", text: "Votre personnage"
    assert_select "input[name=?]", "character[name]"
    assert_select "label[for=character_name] > span[aria-hidden=true]", text: "*"
    assert_select "fieldset legend", text: "Caractéristiques"
    assert_select "select[name=?] option", "character[sheet][class]", count: 3
    assert_select "input[type=number][name=?][min='1'][max='20']", "character[sheet][strength]"
    assert_select "label[for=character_sheet_inspiration]", text: "Inspiration"
    assert_select "input[type=checkbox][role=switch][name=?][value='1']:not([checked])", "character[sheet][inspiration]"
    assert_select "textarea[name=?]", "character[sheet][background]"
    assert_select "p", text: "En quelques mots"
  end

  test "the character part is in two columns, the combat in boxes with minus and plus" do
    fields = [
      { "key" => "class", "label" => "Classe", "type" => "choice", "section" => "Identité", "options" => %w[Mage] },
      { "key" => "level", "label" => "Niveau", "type" => "number", "min" => 1, "max" => 20, "section" => "Identité" },
      { "key" => "ideals", "label" => "Idéaux", "type" => "text", "column" => "aside", "section" => "Identité" },
      { "key" => "dexterity", "label" => "Dextérité", "type" => "ability", "modifier" => "half_above_ten",
        "section" => "Caractéristiques" },
      { "key" => "armor_class", "label" => "Classe d'armure", "type" => "number", "section" => "Combat" },
      { "key" => "initiative", "label" => "Initiative", "type" => "computed", "rule" => "ability_modifier",
        "based_on" => "dexterity", "section" => "Combat" },
      { "key" => "hit_dice", "label" => "Dés de vie", "type" => "text", "short" => true, "section" => "Combat" }
    ]
    @game_table.update!(template_snapshot: { "character_fields" => { "fields" => fields } })
    sign_in @player
    post game_table_character_path(@game_table), params: { character: { name: "", sheet: { dexterity: "15" } } }

    assert_select "fieldset:first-of-type .lg\\:grid-cols-2" do
      assert_select "input[name=?]", "character[name]"
      assert_select "textarea[name=?]", "character[sheet][ideals]"
      assert_select ".rounded-xl [data-controller=number-stepper] input[name=?]", "character[sheet][level]"
    end
    assert_select "[data-controller=number-stepper]:has(input[name=?])", "character[sheet][armor_class]" do
      assert_select "input[type=number][class*='appearance:textfield']"
      assert_select "button[aria-label=?]", "Augmenter Classe d'armure"
    end
    assert_select "output[data-key=initiative]", text: "+2"
    assert_select "input[type=text][name=?]", "character[sheet][hit_dice]"
  end

  test "a list with effects gives them to the live calculation, and its skills get a count to pick" do
    class_effects = { "Mage" => { "proficient" => ["arcana"],
                                  "skill_choices" => { "count" => 1, "from" => ["arcana"] } } }
    fields = [
      { "key" => "class", "label" => "Classe", "type" => "choice", "section" => "Identité",
        "options" => %w[Mage Guerrier], "effects" => class_effects },
      { "key" => "intelligence", "label" => "Intelligence", "type" => "ability", "modifier" => "half_above_ten",
        "section" => "Caractéristiques" },
      { "key" => "arcana", "label" => "Arcanes", "type" => "bonus", "based_on" => "intelligence",
        "section" => "Compétences" }
    ]
    @game_table.update!(template_snapshot: { "character_fields" => { "fields" => fields } })
    sign_in @player
    get new_game_table_character_path(@game_table)

    assert_select "select[name=?][data-character-sheet-target=effectChoice][data-action=?]",
                  "character[sheet][class]", "character-sheet#applyEffects" do |selects|
      assert_equal class_effects, JSON.parse(selects.first["data-effects"])
    end
    assert_select "[data-character-sheet-target=bonusRow][data-key=arcana]", text: /Proposée/
    assert_select "p[hidden][role=status][data-character-sheet-target=skillChoices]" do |paragraphs|
      assert_includes paragraphs.first["data-template"], "choisissez"
    end
  end

  test "a number with a step of a half takes decimals, with a comma too, but only multiples of its step" do
    fields = [{ "key" => "speed", "label" => "Vitesse (m)", "type" => "number", "min" => 0, "max" => 36,
                "step" => 0.5, "section" => "Combat" }]
    @game_table.update!(template_snapshot: { "character_fields" => { "fields" => fields } })
    sign_in @player
    post game_table_character_path(@game_table), params: { character: { name: "Aldric", sheet: { speed: "10.3" } } }
    assert_response :unprocessable_content
    assert_select "input[name=?][step='0.5'][aria-invalid=true]", "character[sheet][speed]"

    post game_table_character_path(@game_table), params: { character: { name: "Aldric", sheet: { speed: "10,5" } } }
    assert_in_delta 10.5, @participation.reload.character.sheet["speed"]
  end

  test "a state of the game (at_creation false) is neither asked nor stored at creation" do
    fields = SHEET_FIELDS.map { |field| field["key"] == "inspiration" ? field.merge("at_creation" => false) : field }
    @game_table.update!(template_snapshot: { "character_fields" => { "fields" => fields } })
    sign_in @player
    get new_game_table_character_path(@game_table)
    assert_select "input[name=?]", "character[sheet][inspiration]", count: 0

    post game_table_character_path(@game_table),
         params: { character: { name: "Aldric", sheet: { inspiration: "1" } } }
    assert_not @participation.reload.character.sheet.key?("inspiration")
  end

  test "the help of a short field is a note under its row, tied to the field" do
    sign_in @player
    get new_game_table_character_path(@game_table)

    note = css_select("p[id^=character_sheet_note_]").find { |paragraph| paragraph.text.include?("Points de vie") }
    assert_includes note.text, "Valeur maximale"
    assert_select "input[name=?][aria-describedby=?]", "character[sheet][hp]", note["id"]
  end

  test "abilities show in tiles with their modifier, skills in rows with their worked out bonus" do
    fields = [
      { "key" => "experience", "label" => "Expérience", "type" => "experience", "section" => "Identité" },
      { "key" => "strength", "label" => "Force", "abbreviation" => "FOR", "type" => "ability", "min" => 1, "max" => 30,
        "modifier" => "half_above_ten", "section" => "Caractéristiques" },
      { "key" => "proficiency_bonus", "label" => "Bonus de maîtrise", "type" => "computed",
        "rule" => "proficiency_by_level", "section" => "Combat" },
      { "key" => "athletics", "label" => "Athlétisme", "type" => "bonus", "based_on" => "strength",
        "proficiency" => "proficiency_bonus", "section" => "Compétences", "help" => "Cochez ce que vous maîtrisez." }
    ]
    level_thresholds = [{ "level" => 1, "experience" => 0, "proficiency_bonus" => 2 }]
    @game_table.update!(template_snapshot: { "level_thresholds" => level_thresholds,
                                             "character_fields" => { "fields" => fields } })
    sign_in @player
    post game_table_character_path(@game_table),
         params: { character: { name: "", sheet: { strength: "14", athletics: "1" } } }

    assert_select "form[data-controller=character-sheet]"
    assert_select "label[for=character_sheet_strength]", text: "Force"
    assert_select "input[name=?][data-character-sheet-target=score][value='14']", "character[sheet][strength]"
    assert_select "output[data-character-sheet-target=modifier][data-ability=strength]", text: "+2"
    assert_select "[data-controller=number-stepper]" do
      assert_select "button[hidden][aria-label=?][data-action='number-stepper#decrease']", "Diminuer Force"
      assert_select "button[hidden][aria-label=?][data-action='number-stepper#increase']", "Augmenter Force"
    end
    assert_select "output[data-character-sheet-target=computed][data-key=proficiency_bonus]", text: "+2"
    assert_select "input[type=checkbox][name=?][checked]", "character[sheet][athletics]"
    assert_select "label[for=character_sheet_athletics] span", text: "FOR"
    assert_select "output[data-character-sheet-target=bonus][data-based-on=strength]", text: "+4"
    assert_select "fieldset p", text: "Cochez ce que vous maîtrisez."
  end

  test "a valid sheet makes the character and leads to the table" do
    sign_in @player
    post game_table_character_path(@game_table), params: { character: {
      name: "Aldric", sheet: { class: "Mage", strength: "12", hp: "9", inspiration: "1", background: "" }
    } }

    character = @participation.reload.character
    assert_equal "Aldric", character.name
    assert_equal({ "class" => "Mage", "strength" => 12, "hp" => { "current" => 9, "max" => 9 }, "inspiration" => true },
                 character.sheet)
    assert_redirected_to game_table_path(@game_table)
  end

  test "a wrong value shows the form again, with its error under the field" do
    sign_in @player
    post game_table_character_path(@game_table), params: { character: { name: "Aldric", sheet: { strength: "25" } } }

    assert_response :unprocessable_content
    assert_nil @participation.reload.character
    assert_select "input[name=?][aria-invalid=true][value='25'][aria-describedby=?]",
                  "character[sheet][strength]", "character_sheet_strength_error"
    assert_select "p#character_sheet_strength_error", text: /20/
  end

  test "until the character is made, the page of the table leads to it" do
    sign_in @player
    get game_table_path(@game_table)

    assert_redirected_to new_game_table_character_path(@game_table)
  end

  test "a player who has a character goes to the table, not to a second sheet" do
    @participation.create_character!(game_table: @game_table, name: "Aldric")
    sign_in @player
    get new_game_table_character_path(@game_table)

    assert_redirected_to game_table_path(@game_table)
  end

  test "only a player of the table makes a character there" do
    sign_in @game_table.participations.game_master.first.user
    get new_game_table_character_path(@game_table)
    assert_response :not_found

    @participation.update!(status: :pending)
    sign_in @player
    get new_game_table_character_path(@game_table)
    assert_response :not_found
  end
end
