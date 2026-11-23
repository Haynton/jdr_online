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
    get sheet_step_path

    assert_response :success
    assert_select "main h1", text: "Fiche"
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
    patch sheet_step_path, params: { character: { name: "", sheet: { dexterity: "15" } } }
    get sheet_step_path

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
    get sheet_step_path

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
    patch sheet_step_path, params: { character: { name: "Aldric", sheet: { speed: "10.3" } } }
    assert_response :unprocessable_content
    assert_select "input[name=?][step='0.5'][aria-invalid=true]", "character[sheet][speed]"

    patch sheet_step_path, params: { character: { name: "Aldric", sheet: { speed: "10,5" } } }
    assert_in_delta 10.5, @participation.reload.character.sheet["speed"]
  end

  test "a state of the game (at_creation false) is neither asked nor stored at creation" do
    fields = SHEET_FIELDS.map { |field| field["key"] == "inspiration" ? field.merge("at_creation" => false) : field }
    @game_table.update!(template_snapshot: { "character_fields" => { "fields" => fields } })
    sign_in @player
    get sheet_step_path
    assert_select "input[name=?]", "character[sheet][inspiration]", count: 0

    patch sheet_step_path, params: { character: { name: "Aldric", sheet: { inspiration: "1" } } }
    assert_not @participation.reload.character.sheet.key?("inspiration")
  end

  test "the help of a short field is a note under its row, tied to the field" do
    sign_in @player
    get sheet_step_path

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
    patch sheet_step_path, params: { character: { name: "", sheet: { strength: "14", athletics: "1" } } }
    get sheet_step_path

    assert_select "form[data-controller~=character-sheet]"
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

  test "a valid sheet is saved as a draft, then the summary makes the character and leads to the table" do
    sign_in @player
    patch sheet_step_path, params: { character: {
      name: "Aldric", sheet: { class: "Mage", strength: "12", hp: "9", inspiration: "1", background: "" }
    } }

    character = @participation.reload.character
    assert_predicate character, :draft?
    assert_equal "Aldric", character.name
    assert_equal({ "class" => "Mage", "strength" => 12, "hp" => { "current" => 9, "max" => 9 }, "inspiration" => true },
                 character.sheet)
    assert_redirected_to game_table_character_step_path(@game_table, "summary")

    follow_redirect!
    assert_select "h2#summary_sheet", text: "Aldric"
    assert_select "dd", text: "Mage"
    assert_select "div.rounded-lg", text: /Force\s+12/
    patch game_table_character_step_path(@game_table, "summary")
    assert_predicate character.reload, :complete?
    assert_redirected_to game_table_path(@game_table)
  end

  test "the summary refuses a character without a name and says so" do
    sign_in @player
    patch sheet_step_path, params: { character: { name: "", sheet: { class: "Mage" } } }
    patch game_table_character_step_path(@game_table, "summary")

    assert_response :unprocessable_content
    assert_predicate @participation.reload.character, :draft?
    assert_select "[role=alert]", text: /Nom/
  end

  test "a wrong value shows the form again, with its error under the field" do
    sign_in @player
    patch sheet_step_path, params: { character: { name: "Aldric", sheet: { strength: "25" } } }

    assert_response :unprocessable_content
    assert_nil @participation.reload.character
    assert_select "input[name=?][aria-invalid=true][value='25'][aria-describedby=?]",
                  "character[sheet][strength]", "character_sheet_strength_error"
    assert_select "p#character_sheet_strength_error", text: /20/
  end

  test "the steps come in order, each saving the draft; a step not reached or unknown leads back to the current one" do
    use_template_with_steps
    sign_in @player

    get new_game_table_character_path(@game_table)
    assert_redirected_to game_table_character_step_path(@game_table, "class")
    get game_table_character_step_path(@game_table, "description")
    assert_redirected_to new_game_table_character_path(@game_table)
    get game_table_character_step_path(@game_table, "renamed")
    assert_redirected_to new_game_table_character_path(@game_table)

    patch game_table_character_step_path(@game_table, "class"), params: { character: { sheet: { class: "Mage" } } }
    assert_redirected_to game_table_character_step_path(@game_table, "spells")
    patch game_table_character_step_path(@game_table, "class"), params: { character: { sheet: { class: "Guerrier" } } }
    assert_redirected_to game_table_character_step_path(@game_table, "description")
    get game_table_character_step_path(@game_table, "spells")
    assert_redirected_to new_game_table_character_path(@game_table)
  end

  test "leaving a step by Back, Later or the band saves it, without reaching the next step" do
    use_template_with_steps
    sign_in @player
    patch game_table_character_step_path(@game_table, "class"), params: { character: { sheet: { class: "Mage" } } }
    patch game_table_character_step_path(@game_table, "spells"),
          params: { go_to: "class", character: { sheet: { spell_notes: "Boule de feu" } } }

    assert_redirected_to game_table_character_step_path(@game_table, "class")
    character = @participation.reload.character
    assert_equal "Boule de feu", character.sheet["spell_notes"]
    assert_equal "spells", character.creation_step
    patch game_table_character_step_path(@game_table, "class"),
          params: { go_to: "later", character: { sheet: { class: "Mage" } } }
    assert_redirected_to game_tables_path(table: @game_table.id)
    get game_table_character_step_path(@game_table, "spells")
    assert_select "a[data-save-step-key=class]"
    assert_select "form button[name=go_to][value=class]", text: "Retour"
  end

  test "a field of picks offers its options as check boxes, the granted ones shown, count at most" do
    fields = [{ "key" => "languages", "label" => "Langues", "type" => "picks", "section" => "Identité", "count" => 2,
                "granted" => ["Commun"], "options" => %w[Elfique Nain Orc] }]
    @game_table.update!(template_snapshot: { "character_fields" => { "fields" => fields } })
    sign_in @player
    get sheet_step_path
    assert_select "fieldset legend", text: "Langues"
    assert_select "input[type=checkbox][disabled][checked]:not([name])", count: 1
    assert_select "input[type=checkbox][name=?]", "character[sheet][languages][]", count: 3

    patch sheet_step_path, params: { character: { name: "Aldric", sheet: { languages: ["", "Elfique", "Nain", "Orc"] } } }
    assert_response :unprocessable_content
    assert_select "fieldset[aria-invalid=true] p", text: /2 au plus/

    patch sheet_step_path, params: { character: { name: "Aldric", sheet: { languages: ["", "Elfique"] } } }
    assert_equal ["Elfique"], @participation.reload.character.sheet["languages"]
    follow_redirect!
    assert_select "dd", text: "Commun et Elfique"
  end

  test "the abilities a background raises take +0, +1 or +2, spread as the rules say, never past the maximum" do
    fields = [
      { "key" => "background", "label" => "Historique", "type" => "choice", "section" => "Origine",
        "options" => %w[Sage], "effects" => { "Sage" => { "ability_bonus_choices" => %w[intelligence wisdom] } } },
      { "key" => "intelligence", "label" => "Intelligence", "type" => "ability", "max" => 20,
        "modifier" => "half_above_ten", "section" => "Caractéristiques" },
      { "key" => "wisdom", "label" => "Sagesse", "type" => "ability", "max" => 20, "modifier" => "half_above_ten",
        "section" => "Caractéristiques" },
      { "key" => "ability_bonuses", "label" => "Bonus de l'historique", "type" => "ability_bonuses",
        "from" => "background", "total" => 3, "max_per_ability" => 2, "help" => "Répartissez +2 et +1.",
        "section" => "Caractéristiques" }
    ]
    @game_table.update!(template_snapshot: { "character_fields" => { "fields" => fields } })
    sign_in @player
    send_bonuses = lambda do |bonuses, intelligence: "15"|
      patch sheet_step_path, params: { character: { name: "Aldric", sheet: {
        background: "Sage", intelligence: intelligence, wisdom: "12", ability_bonuses: bonuses
      } } }
    end

    send_bonuses.call({ intelligence: "2", wisdom: "2" })
    assert_response :unprocessable_content
    send_bonuses.call({ intelligence: "2", wisdom: "0" }, intelligence: "19")
    assert_select "p", text: /dépasse 20 avec le bonus/
    send_bonuses.call({ intelligence: "2", wisdom: "1" })
    assert_equal({ "intelligence" => 2, "wisdom" => 1 }, @participation.reload.character.sheet["ability_bonuses"])

    get sheet_step_path
    assert_select "span#bonus_intelligence_label", text: "Intelligence"
    assert_select "[role=radiogroup][aria-labelledby=bonus_intelligence_label] input[type=radio][value='2'][checked]"
    assert_select "[data-character-sheet-target=bonusNote][data-ability=intelligence][data-template=?]",
                  "dont +#{CharacterSheets::AbilityBonusesHelper::BONUS_PLACEHOLDER} Sage"
    assert_select "output[data-character-sheet-target=finalScore][data-ability=intelligence]", text: "17"
    assert_select "output[data-character-sheet-target=modifier][data-ability=intelligence]", text: "+3"
    assert_select "p", text: /Répartissez \+2 et \+1\./
  end

  test "the bonus of a background follows the rule of its template, not the one of the heroic fantasy" do
    fields = [
      { "key" => "background", "label" => "Passé", "type" => "choice", "section" => "Origine", "options" => %w[Marin],
        "effects" => { "Marin" => { "ability_bonus_choices" => %w[strength agility] } } },
      { "key" => "strength", "label" => "Force", "type" => "ability", "modifier" => "half_above_ten",
        "section" => "Caractéristiques" },
      { "key" => "agility", "label" => "Agilité", "type" => "ability", "modifier" => "half_above_ten",
        "section" => "Caractéristiques" },
      { "key" => "ability_bonuses", "label" => "Bonus du passé", "type" => "ability_bonuses", "from" => "background",
        "total" => 2, "max_per_ability" => 1, "help" => "+1 à deux caractéristiques.", "section" => "Caractéristiques" }
    ]
    @game_table.update!(template_snapshot: { "character_fields" => { "fields" => fields } })
    sign_in @player
    send_bonuses = lambda do |bonuses|
      patch sheet_step_path, params: { character: { name: "Mira", sheet: {
        background: "Marin", strength: "12", agility: "12", ability_bonuses: bonuses
      } } }
    end

    send_bonuses.call({ strength: "2" })
    assert_response :unprocessable_content
    send_bonuses.call({ strength: "1", agility: "1" })
    assert_equal({ "strength" => 1, "agility" => 1 }, @participation.reload.character.sheet["ability_bonuses"])

    get sheet_step_path
    assert_select "[role=radiogroup][aria-labelledby=bonus_strength_label] input[type=radio]", count: 2
    assert_select "[data-ability-bonus-total-value='2'][data-ability-bonus-max-per-ability-value='1']"
    assert_select "p", text: /\+1 à deux caractéristiques\./
  end

  test "a required list keeps its step until it is picked" do
    use_template_with_steps
    sign_in @player
    patch game_table_character_step_path(@game_table, "class"), params: { character: { sheet: { class: "" } } }

    assert_response :unprocessable_content
    assert_nil @participation.reload.character
    assert_select "select[name=?][aria-invalid=true]", "character[sheet][class]"
  end

  test "a draft starts at the level of the table and is resumed where it stopped" do
    use_template_with_steps
    @game_table.update!(starting_level: 3)
    sign_in @player
    patch game_table_character_step_path(@game_table, "class"), params: { character: { sheet: { class: "Guerrier" } } }

    assert_equal 3, @participation.reload.character.sheet["level"]
    get new_game_table_character_path(@game_table)
    assert_redirected_to game_table_character_step_path(@game_table, "description")
    get game_tables_path(table: @game_table.id)
    assert_select "a[href=?]", new_game_table_character_path(@game_table), text: "Reprendre mon personnage"
  end

  test "an option changed on its step applies its effects to the fields of other steps" do
    use_template_with_steps
    sign_in @player
    patch game_table_character_step_path(@game_table, "class"), params: { character: { sheet: { class: "Mage" } } }
    patch game_table_character_step_path(@game_table, "class"), params: { character: { sheet: { class: "Guerrier" } } }

    assert_equal({ "class" => "Guerrier", "level" => 1, "arcana" => false, "speed" => 9 },
                 @participation.reload.character.sheet)
  end

  test "the lists with descriptions show a summary of the option picked; the worked out values are kept at the end" do
    fields = [
      { "key" => "class", "label" => "Classe", "type" => "choice", "section" => "Personnage",
        "options" => %w[Mage Guerrier], "descriptions" => { "Mage" => "Un érudit.", "Guerrier" => "Un soldat." },
        "effects" => { "Mage" => { "hit_die" => 6 }, "Guerrier" => { "hit_die" => 10 } } },
      { "key" => "constitution", "label" => "Constitution", "type" => "ability", "modifier" => "half_above_ten",
        "section" => "Personnage" },
      { "key" => "max_hp", "label" => "Points de vie", "type" => "computed", "rule" => "hit_points_by_level",
        "class_from" => "class", "based_on" => "constitution", "section" => "Personnage" },
      { "key" => "hp", "label" => "Points de vie", "type" => "resource", "at_creation" => false,
        "initial_from" => "max_hp", "section" => "Personnage" }
    ]
    @game_table.update!(template_snapshot: { "character_fields" => { "fields" => fields } })
    sign_in @player
    patch sheet_step_path, params: { character: { name: "Aldric", sheet: { class: "Mage", constitution: "14" } } }
    get sheet_step_path

    assert_select "[data-controller=described-choices] aside" do
      assert_select "[data-option=Mage]:not([hidden])", text: /Un érudit\.\s+Dé de vie\s+d6/
      assert_select "[data-option=Guerrier][hidden]"
    end
    patch game_table_character_step_path(@game_table, "summary")
    assert_equal({ "current" => 8, "max" => 8 }, @participation.reload.character.sheet["hp"])
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
    sign_in @game_table.participations.game_master.first.user
    get game_table_character_step_path(@game_table, "sheet")
    assert_response :not_found

    @participation.update!(status: :pending)
    sign_in @player
    get new_game_table_character_path(@game_table)
    assert_response :not_found
  end

  test "the level is never asked when the table sets it" do
    use_template_with_steps
    @game_table.update!(starting_level: 3)
    sign_in @player
    get game_table_character_step_path(@game_table, "class")

    assert_select "input[name=?]", "character[sheet][level]", count: 0
  end

  test "when the players choose their level, it is asked on the first page, starting from the level of the table" do
    use_template_with_steps
    @game_table.update!(starting_level: 3, players_choose_level: true)
    sign_in @player
    get game_table_character_step_path(@game_table, "class")

    assert_select "input[name=?][value='3']", "character[sheet][level]"
    patch game_table_character_step_path(@game_table, "class"),
          params: { character: { sheet: { class: "Guerrier", level: "5" } } }
    assert_equal 5, @participation.reload.character.sheet["level"]
    get game_table_character_step_path(@game_table, "description")
    assert_select "input[name=?]", "character[sheet][level]", count: 0
  end

  test "the form of a step saves itself in the background" do
    sign_in @player
    get sheet_step_path

    assert_select "form[data-controller~=autosave][data-autosave-url-value=?]",
                  draft_game_table_character_step_path(@game_table, "sheet")
  end

  test "a draft saved in the background keeps the values, without reaching the next step" do
    use_template_with_steps
    sign_in @player
    patch draft_game_table_character_step_path(@game_table, "class"),
          params: { character: { sheet: { class: "Mage" } } }

    assert_response :no_content
    character = @participation.reload.character
    assert_equal "Mage", character.sheet["class"]
    assert_equal 9, character.sheet["speed"]
    assert character.draft?
    assert_nil character.creation_step
  end

  test "a required field may stay empty in a draft saved in the background" do
    use_template_with_steps
    sign_in @player
    patch draft_game_table_character_step_path(@game_table, "class"), params: { character: { sheet: { class: "" } } }

    assert_response :no_content
    assert_predicate @participation.reload.character, :persisted?
  end

  test "a value refused in the background keeps the one saved before, the others are saved" do
    sign_in @player
    patch draft_game_table_character_step_path(@game_table, "sheet"),
          params: { character: { sheet: { strength: "12" } } }
    patch draft_game_table_character_step_path(@game_table, "sheet"),
          params: { character: { name: "Aldric", sheet: { strength: "45", class: "Mage", background: "Né à Brume" } } }

    character = @participation.reload.character
    assert_equal 12, character.sheet["strength"]
    assert_equal "Mage", character.sheet["class"]
    assert_equal "Né à Brume", character.sheet["background"]
    assert_equal "Aldric", character.name
  end

  test "only the player of the character saves its draft in the background" do
    sign_in @game_table.participations.game_master.first.user
    patch draft_game_table_character_step_path(@game_table, "sheet"), params: { character: { name: "Intrus" } }

    assert_response :not_found
    assert_not Character.exists?(name: "Intrus")
  end

  private

  # A template without creation steps asks everything in one step, "sheet"
  def sheet_step_path
    game_table_character_step_path(@game_table, "sheet")
  end

  # Steps declared by the template: the class, the spells for a class with spells, then the name. Picking the mage
  # ticks Arcana and sets the speed (effects); the level comes from the table
  def use_template_with_steps
    class_effects = { "Mage" => { "proficient" => ["arcana"], "set" => { "speed" => 9 }, "spellcasting" => {} },
                      "Guerrier" => { "set" => { "speed" => 9 } } }
    fields = [
      { "key" => "class", "label" => "Classe", "type" => "choice", "section" => "Classe", "required" => true,
        "options" => %w[Mage Guerrier], "effects" => class_effects },
      { "key" => "level", "label" => "Niveau", "type" => "number", "from_table" => "starting_level",
        "section" => "Notes" },
      { "key" => "arcana", "label" => "Arcanes", "type" => "bonus", "based_on" => "intelligence",
        "section" => "Notes" },
      { "key" => "speed", "label" => "Vitesse", "type" => "number", "section" => "Notes" },
      { "key" => "spell_notes", "label" => "Sorts", "type" => "text", "section" => "Sorts" }
    ]
    steps = [{ "key" => "class", "label" => "Classe", "sections" => ["Classe"] },
             { "key" => "spells", "label" => "Sorts", "sections" => ["Sorts"], "only_with_effect" => "spellcasting" },
             { "key" => "description", "label" => "Description", "sections" => ["Notes"], "asks_name" => true }]
    @game_table.update!(template_snapshot: { "character_fields" => { "creation_steps" => steps, "fields" => fields } })
  end
end
