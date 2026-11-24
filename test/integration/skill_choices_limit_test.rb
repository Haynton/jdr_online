require "test_helper"

# The skills a player ticks, limited or not by the table to what the class offers (limit_skill_choices, step Settings)
class SkillChoicesLimitTest < ActionDispatch::IntegrationTest
  # The ranger offers 2 skills among Stealth, Survival, Perception and Athletics, the wizard Arcana; the criminal
  # background gives Stealth
  CLASS_EFFECTS = { "Rôdeur" => { "skill_choices" => { "count" => 2,
                                                       "from" => %w[stealth survival perception athletics] } },
                    "Magicien" => { "skill_choices" => { "count" => 1, "from" => %w[arcana] } } }.freeze
  BACKGROUND_EFFECTS = { "Criminel" => { "proficient" => ["stealth"] } }.freeze
  FIELDS = [
    { "key" => "class", "label" => "Classe", "type" => "choice", "section" => "Identité",
      "options" => %w[Rôdeur Magicien], "effects" => CLASS_EFFECTS },
    { "key" => "background", "label" => "Historique", "type" => "choice", "section" => "Identité",
      "options" => ["Criminel"], "effects" => BACKGROUND_EFFECTS },
    { "key" => "stealth", "label" => "Discrétion", "type" => "bonus", "section" => "Compétences" },
    { "key" => "survival", "label" => "Survie", "type" => "bonus", "section" => "Compétences" },
    { "key" => "perception", "label" => "Perception", "type" => "bonus", "section" => "Compétences" },
    { "key" => "athletics", "label" => "Athlétisme", "type" => "bonus", "section" => "Compétences" },
    { "key" => "arcana", "label" => "Arcanes", "type" => "bonus", "section" => "Compétences" }
  ].freeze

  setup do
    game_master = User.create!(email: "julien@example.com", username: "Julien", password: TEST_PASSWORD)
    @player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS,
                                    template_snapshot: { "character_fields" => { "fields" => FIELDS } })
    @game_table.participations.create!(user: game_master, role: :game_master)
    @participation = @game_table.participations.create!(user: @player, role: :player)
    sign_in @player
  end

  test "a table limits the skills by default" do
    assert @game_table.limit_skill_choices
    assert @game_table.asks_skill_choices?
  end

  test "the skills offered may be ticked up to their count, those of the background staying ticked" do
    send_skills(stealth: "1", survival: "1", perception: "1")

    assert_redirected_to game_table_character_step_path(@game_table, "summary")
    sheet = @participation.reload.character.sheet
    assert sheet["stealth"]
    assert sheet["perception"]
  end

  test "more skills than the class offers are refused, with a message" do
    send_skills(survival: "1", perception: "1", athletics: "1")

    assert_response :unprocessable_content
    assert_select "p.text-error-ink", text: /2 au plus parmi celles proposées/
  end

  test "a skill the class does not offer is refused" do
    send_skills(arcana: "1")

    assert_response :unprocessable_content
    assert_select "p.text-error-ink", text: /Arcanes n'est pas proposée par vos choix/
  end

  test "a table that does not limit the skills lets the player tick any of them" do
    @game_table.update!(limit_skill_choices: false)
    send_skills(survival: "1", perception: "1", arcana: "1")

    assert_redirected_to game_table_character_step_path(@game_table, "summary")
    assert @participation.reload.character.sheet["arcana"]
  end

  test "the count under the skills is marked limited only when the table limits them" do
    get game_table_character_step_path(@game_table, "sheet")
    assert_select "p[data-character-sheet-target=skillChoices][data-limited]"

    @game_table.update!(limit_skill_choices: false)
    get game_table_character_step_path(@game_table, "sheet")
    assert_select "p[data-character-sheet-target=skillChoices]:not([data-limited])"
  end

  test "a skill refused in the background keeps the value saved before" do
    patch draft_game_table_character_step_path(@game_table, "sheet"),
          params: { character: { sheet: { class: "Rôdeur", background: "Criminel", arcana: "1" } } }

    assert_not @participation.reload.character.sheet["arcana"]
    assert_equal "Rôdeur", @participation.character.sheet["class"]
  end

  private

  # On the only step of the sheet, with the ranger and the criminal
  def send_skills(**skills)
    patch game_table_character_step_path(@game_table, "sheet"),
          params: { character: { name: "Aldric", sheet: { class: "Rôdeur", background: "Criminel", **skills } } }
  end
end
