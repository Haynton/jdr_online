require "test_helper"

# The spells of the origin feat of the background at the step of the feats: the acolyte picks those of Magic Initiate
# in the cleric list; going on without them is refused
class FeatSpellsStepTest < ActionDispatch::IntegrationTest
  setup do
    template_file = Rails.root.join("db/seeds/sheet_templates/heroic_fantasy.fr.json")
    template = SheetTemplate.find_or_create_by!(JSON.parse(template_file.read(encoding: "UTF-8")))
    Catalogs::Loader.new(Rails.root.join("db/seeds/catalogs/heroic_fantasy_spells.fr.json")).call
    Catalogs::Loader.new(Rails.root.join("db/seeds/catalogs/heroic_fantasy_features.fr.json")).call
    @game_table = GameTable.new(name: "La Crypte", starting_level: 1, status: GameTable::READY_STATUS)
    @game_table.use_sheet_template(template)
    @game_table.save!
    @player = User.create!(email: "player@example.com", username: "joueur", password: TEST_PASSWORD, locale: "fr")
    participation = @game_table.participations.create!(user: @player, role: :player)
    @character = participation.create_character!(game_table: @game_table, kind: :pc, status: :draft, creation_step: "feats",
                                                 sheet: { "class" => "Guerrier", "background" => "Acolyte", "level" => 1 })
  end

  test "the acolyte picks the spells of Magic Initiate in the cleric list at the step of the feats" do
    sign_in @player
    get game_table_character_step_path(@game_table, "feats")
    assert_select "h2", text: /\AInitié à la magie : Clerc\s+Don de votre historique · Donné par votre historique \(Acolyte\)/
    assert_select "label input[type=radio][name='character[feat_spells][spell_ability]'][value=wisdom]"
    assert_select "input[name='character[feat_spells][cantrips][]'][value=?]", "sacred-flame"
    assert_select "input[name='character[feat_spells][spell]'][value=?]", "bless"

    patch game_table_character_step_path(@game_table, "feats"),
          params: { character: { feat_spells: { spell_ability: "wisdom", cantrips: ["guidance"] } } }
    assert_response :unprocessable_content

    patch game_table_character_step_path(@game_table, "feats"),
          params: { character: { feat_spells: { spell_ability: "wisdom", cantrips: %w[guidance sacred-flame], spell: "bless" } } }
    assert_equal %w[bless guidance sacred-flame], @character.reload.spells.pluck("key").sort
  end

  test "the human picks an origin feat on a step of its own, after the feats, and its skills are not class picks" do
    @character.update!(sheet: @character.sheet.merge("species" => "Humain"))
    sign_in @player
    pick_background_spells
    assert_redirected_to game_table_character_step_path(@game_table, "species_feat")
    get game_table_character_step_path(@game_table, "species_feat")
    assert_select "input[name='character[species_feat][key]'][value=?]", "skilled"

    patch game_table_character_step_path(@game_table, "species_feat"),
          params: { character: { species_feat: { key: "skilled", skills: %w[arcana history stealth] } } }
    @character.reload
    entry = @character.feats.find { |feat| feat["source"] == "species" }
    assert_equal %w[arcana history stealth], entry["skills"]
    assert @character.sheet["stealth"]
  end

  test "the human must pick what its origin feat asks" do
    @character.update!(sheet: @character.sheet.merge("species" => "Humain"))
    sign_in @player
    pick_background_spells
    patch game_table_character_step_path(@game_table, "species_feat"),
          params: { character: { species_feat: { key: "skilled", skills: %w[arcana] } } }
    assert_response :unprocessable_content
  end

  test "the skills of the origin feat of the human are skills only, never a saving throw" do
    @character.update!(sheet: @character.sheet.merge("species" => "Humain"))
    sign_in @player
    pick_background_spells
    patch game_table_character_step_path(@game_table, "species_feat"),
          params: { character: { species_feat: { key: "skilled",
                                                 skills: %w[strength_save dexterity_save constitution_save] } } }
    assert_response :unprocessable_content
    assert_not @character.reload.sheet["dexterity_save"]
  end

  test "the trait of the human adds one skill of any list, but only one outside the list of its class" do
    @character.update!(sheet: @character.sheet.merge("species" => "Humain"))
    sign_in @player
    spells = { spell_ability: "wisdom", cantrips: %w[guidance sacred-flame], spell: "bless" }
    patch game_table_character_step_path(@game_table, "feats"),
          params: { character: { feat_spells: spells, species_feat: { key: "alert" } } }
    patch game_table_character_step_path(@game_table, "skills"),
          params: { character: { sheet: { athletics: "1", nature: "1", arcana: "1" } } }
    assert_response :unprocessable_content

    patch game_table_character_step_path(@game_table, "skills"),
          params: { character: { sheet: { athletics: "1", intimidation: "1", nature: "1" } } }
    assert @character.reload.sheet["nature"]
  end

  test "the step of the feats shows the feat of a criminal with nothing to pick, and goes when the table has no origin feats" do
    @character.update!(sheet: @character.sheet.merge("background" => "Criminel"))
    sign_in @player
    get game_table_character_step_path(@game_table, "feats")
    assert_select "h2 span", text: "Vigilance"
    assert_select "p", text: "Rien à choisir : ce don est déjà à vous."

    @game_table.update!(origin_feats: false)
    assert_not_includes @character.reload.creation_steps.all.map(&:key), "feats"
  end

  private

  # The spells of the background's feat, picked: the step of the feats is done, the one of the species' feat opens
  def pick_background_spells
    patch game_table_character_step_path(@game_table, "feats"),
          params: { character: { feat_spells: { spell_ability: "wisdom", cantrips: %w[guidance sacred-flame],
                                                 spell: "bless" } } }
  end
end
