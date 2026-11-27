require "test_helper"

# A character created above level 1 gets, by the way of the table (rules of the SRD 5.2.1 by default), more gold and
# magic items: a fighter of level 6 picks a common and an uncommon item at the step of the equipment (a +1 on its
# greatsword), and finishes with 500 gold pieces plus 1d10 × 25 more; the normal equipment only gives nothing more
class HigherLevelEquipmentTest < ActionDispatch::IntegrationTest
  setup do
    template_file = Rails.root.join("db/seeds/sheet_templates/heroic_fantasy.fr.json")
    template = SheetTemplate.find_or_create_by!(JSON.parse(template_file.read(encoding: "UTF-8")))
    %w[items magic].each do |kind|
      Catalogs::Loader.new(Rails.root.join("db/seeds/catalogs/heroic_fantasy_#{kind}.fr.json")).call
    end
    @game_table = GameTable.new(name: "La Forge", starting_level: 6, status: GameTable::READY_STATUS)
    @game_table.use_sheet_template(template)
    @game_table.save!
    @player = User.create!(email: "player@example.com", username: "joueur", password: TEST_PASSWORD, locale: "fr")
    participation = @game_table.participations.create!(user: @player, role: :player)
    @character = participation.create_character!(
      game_table: @game_table, kind: :pc, status: :draft, creation_step: "equipment",
      sheet: { "class" => "Guerrier", "level" => 6, "class_equipment" => { "option" => "a" } }
    )
  end

  test "the step of the equipment offers a common and an uncommon item, a +1 on the greatsword among them" do
    sign_in @player
    get game_table_character_step_path(@game_table, "equipment")

    assert_select "h2", text: "Objets magiques de départ"
    assert_select "p", text: /\+ 500 pièces d'or et 1d10 × 25 pièces d'or/
    assert_select "select[name=?] option[value=?]", "character[starting_magic_items][common-1]", "potion-of-healing"
    assert_select "select[name=?] option[value=?]", "character[starting_magic_items][uncommon-1]",
                  "weapon-plus-1~greatsword", text: "Épée à deux mains +1"
  end

  test "a place left empty is refused on the step" do
    sign_in @player
    patch game_table_character_step_path(@game_table, "equipment"),
          params: { character: { sheet: { "class_equipment" => { "option" => "a" } },
                                 starting_magic_items: { "common-1" => "potion-of-healing" } } }

    assert_response :unprocessable_content
    assert_select "p", text: /Objets magiques de départ demandent l'objet de rareté « Peu commune »/
  end

  test "the magic items and the gold go into the inventory when the character is done" do
    @character.starting_magic_items = { "common-1" => "potion-of-healing", "uncommon-1" => "weapon-plus-1~greatsword" }
    @character.add_higher_level_gold(random: Random.new(1))
    gold = @character.sheet["gold"].to_i
    items = @character.with_starting_magic_items(@character.starting_inventory)

    assert_includes 525..750, gold
    assert_equal ["Potion de soins", "Épée à deux mains +1"], items.last(2).map(&:name)
    assert_not(items.any? { |item| item.key == "greatsword" })
    assert items.last.equipped
  end

  test "the normal equipment only gives no gold nor magic item more" do
    @game_table.update!(rules: { "higher_level_equipment_method" => "normal_only" })

    assert_nil @character.reload.higher_level_equipment_tier
    assert_empty @character.magic_item_places
    assert_equal 0, @character.higher_level_gold
  end

  test "a character of level 1 gets nothing more" do
    @character.update!(sheet: @character.sheet.merge("level" => 1))

    assert_nil @character.higher_level_equipment_tier
  end
end
