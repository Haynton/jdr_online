require "test_helper"

# The groups of choices of a class in the screens: the step of the skills of a warlock offers its invocations, and
# « Changer mes choix de classe » in the game room changes them, written in the chat; a class without choices, a 404
class ClassChoicesRoomTest < ActionDispatch::IntegrationTest
  setup do
    template_file = Rails.root.join("db/seeds/sheet_templates/heroic_fantasy.fr.json")
    template = SheetTemplate.find_or_create_by!(JSON.parse(template_file.read(encoding: "UTF-8")))
    @game_table = GameTable.new(name: "La Crypte", starting_level: 2, status: GameTable::READY_STATUS)
    @game_table.use_sheet_template(template)
    @game_table.save!
    game_master = User.create!(email: "mj@example.com", username: "maitre", password: TEST_PASSWORD)
    @game_table.participations.create!(user: game_master, role: :game_master)
    @player = User.create!(email: "player@example.com", username: "joueur", password: TEST_PASSWORD, locale: "fr")
    @participation = @game_table.participations.create!(user: @player, role: :player)
  end

  test "the step of the skills offers the invocations of a warlock, with their level and the pact they need" do
    @participation.create_character!(game_table: @game_table, kind: :pc, status: :draft, creation_step: "skills",
                                      sheet: { "class" => "Occultiste", "level" => 2 })
    sign_in @player
    get game_table_character_step_path(@game_table, "skills")

    assert_select "legend", text: "Invocations occultes"
    assert_select "input[type=checkbox][name='character[class_choices][eldritch_invocations][]'][value=?]", "devils-sight"
    assert_select "input[value=?]", "thirsting-blade", count: 0
  end

  test "a player changes their invocations in the room, written in the chat; more than the level gives is refused" do
    character = @participation.create_character!(game_table: @game_table, kind: :pc, status: :complete, name: "Vex",
                                                 sheet: { "class" => "Occultiste", "level" => 2 })
    sign_in @player
    get game_table_path(@game_table)
    assert_select "a[href=?]", edit_game_table_class_choice_path(@game_table), text: /Changer mes choix de classe/

    patch game_table_class_choice_path(@game_table),
          params: { character: { class_choices: { eldritch_invocations: ["", "devils-sight", "eldritch-mind"] } } },
          as: :turbo_stream
    assert_equal %w[devils-sight eldritch-mind], character.reload.class_choices["eldritch_invocations"]
    assert_equal "class_choices_changed", ChatMessage.last.event_key

    patch game_table_class_choice_path(@game_table),
          params: { character: { class_choices: { eldritch_invocations: %w[devils-sight eldritch-mind armor-of-shadows misty-visions] } } },
          as: :turbo_stream
    assert_response :unprocessable_content
  end

  test "at level 3, the window prepares what each subclass brings, and one sending is enough" do
    character = @participation.create_character!(game_table: @game_table, kind: :pc, status: :complete, name: "Sylas",
                                                 level_up_to: 3, sheet: { "class" => "Rôdeur", "level" => 2 })
    sign_in @player
    get new_game_table_level_up_path(@game_table)

    assert_select "[data-level-up-subclass-target=block][data-subclass=Chasseur][hidden]" do
      assert_select "legend", text: "Proie du chasseur"
    end

    post game_table_level_up_path(@game_table), params: { level_up: {
      subclass: "Chasseur", class_choices: { hunters_prey: ["", "colossus-slayer"], land_type: ["arid"] }
    } }, as: :turbo_stream

    assert_equal [3, { "hunters_prey" => ["colossus-slayer"] }],
                 [character.reload.sheet["level"], character.class_choices]
  end

  test "a class without choices has none to change" do
    @participation.create_character!(game_table: @game_table, kind: :pc, status: :complete, name: "Brunhild",
                                     sheet: { "class" => "Guerrier", "level" => 2 })
    sign_in @player
    get edit_game_table_class_choice_path(@game_table)

    assert_response :not_found
  end
end
