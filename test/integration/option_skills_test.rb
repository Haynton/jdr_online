require "test_helper"

# The skills an option of a list that depends on another offers (the College of Lore of the bard: 3), on a creation
# step of their own: offered once the subclass is asked, kept apart and ticked on the sheet, no longer counted with the
# skills of the class, no more than the subclass offers
class OptionSkillsTest < ActionDispatch::IntegrationTest
  setup do
    template_file = Rails.root.join("db/seeds/sheet_templates/heroic_fantasy.fr.json")
    template = SheetTemplate.find_or_create_by!(JSON.parse(template_file.read(encoding: "UTF-8")))
    @game_table = GameTable.new(name: "La Crypte", starting_level: 3, status: GameTable::READY_STATUS)
    @game_table.use_sheet_template(template)
    @game_table.save!
    @player = User.create!(email: "player@example.com", username: "joueur", password: TEST_PASSWORD, locale: "fr")
    participation = @game_table.participations.create!(user: @player, role: :player)
    @character = participation.create_character!(
      game_table: @game_table, kind: :pc, status: :draft, creation_step: "subclass_skills",
      sheet: { "class" => "Barde", "subclass" => "Collège du Savoir", "background" => "Sage", "level" => 3 }
    )
  end

  test "the College of Lore offers its skills on their own step, kept apart and ticked" do
    sign_in @player
    get game_table_character_step_path(@game_table, "subclass_skills")

    assert_select "legend", text: /Collège du Savoir/
    assert_select "input[name='character[option_skills][subclass][]'][value=acrobatics]"
    assert_select "input[name='character[option_skills][subclass][]'][value=arcana]", count: 0

    patch game_table_character_step_path(@game_table, "subclass_skills"),
          params: { character: { option_skills: { "subclass" => %w[acrobatics athletics stealth] } } }

    @character.reload
    assert_equal({ "subclass" => %w[acrobatics athletics stealth] }, @character.option_skills)
    assert_equal [true, true, true], @character.sheet.values_at("acrobatics", "athletics", "stealth")
    assert_equal 3, @character.skill_choices.allowed_count
  end

  test "more skills than the subclass offers are refused" do
    sign_in @player
    patch game_table_character_step_path(@game_table, "subclass_skills"),
          params: { character: { option_skills: { "subclass" => %w[acrobatics athletics stealth survival] } } }

    assert_response :unprocessable_content
    assert_select "p[role=alert]", text: /3 au plus/
  end

  test "another subclass drops the skills picked for the one before" do
    @character.choose_option_skills("subclass" => %w[acrobatics athletics])
    @character.sheet = @character.sheet.merge("class" => "Guerrier", "subclass" => "Champion")
    @character.keep_offered_option_skills

    assert_empty @character.option_skills
    assert_nil @character.sheet["acrobatics"]
  end
end
