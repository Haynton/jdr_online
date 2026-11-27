require "test_helper"

# The magic items of the heroic fantasy (SRD 5.2.1): a magic put on an item when the game master gives it
# (Catalogs::Enchantments), and what an item gives the rules once attuned (Attunable): its magic bonus to attack and
# damage or to the armour class, a bonus to the armour class, an ability set to a score; three items attuned at most
class MagicItemsTest < ActiveSupport::TestCase
  setup do
    template_file = Rails.root.join("db/seeds/sheet_templates/heroic_fantasy.fr.json")
    template = SheetTemplate.find_or_create_by!(JSON.parse(template_file.read(encoding: "UTF-8")))
    %w[items magic].each do |kind|
      Catalogs::Loader.new(Rails.root.join("db/seeds/catalogs/heroic_fantasy_#{kind}.fr.json")).call
    end
    @game_table = GameTable.new(name: "La Forge", starting_level: 1, status: GameTable::READY_STATUS)
    @game_table.use_sheet_template(template)
    @game_table.save!
    player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD)
    participation = @game_table.participations.create!(user: player, role: :player)
    @character = participation.create_character!(
      game_table: @game_table, kind: :pc, status: :complete, name: "Brune",
      sheet: { "class" => "Guerrier", "level" => 1, "strength" => 16, "dexterity" => 12, "constitution" => 14 }
    )
  end

  test "a magic goes only on the items it names, and gives its name and its values to the item given" do
    catalog = Catalogs::TableCatalog.new(@game_table).entries("item")
    enchantments = Catalogs::Enchantments.new(@game_table)
    assert_includes enchantments.for(catalog.find_by!(key: "longsword")).map(&:key), "vorpal-sword"
    assert_not_includes enchantments.for(catalog.find_by!(key: "dagger")).map(&:key), "vorpal-sword"
    assert_empty enchantments.for(catalog.find_by!(key: "rope"))

    sword = InventoryItem.from_entry(catalog.find_by!(key: "longsword"), quantity: 1,
                                     enchantment: catalog.find_by!(key: "weapon-plus-1"))
    assert_equal ["Épée longue +1", 1], [sword.name, sword.properties["magic_bonus"]]
    tongue = InventoryItem.from_entry(catalog.find_by!(key: "longsword"), quantity: 1,
                                      enchantment: catalog.find_by!(key: "flame-tongue"))
    assert_equal ["Épée longue, Langue de feu", true], [tongue.name, tongue.requires_attunement?]
  end

  test "a magic weapon adds its bonus to attack and damage, a magic armour to the armour class" do
    give("longsword", "weapon-plus-2", equipped: true)
    give("chain-mail", "armor-plus-1", equipped: true)

    attack = CharacterSheets::WeaponAttacks.new(@character.reload).call.first
    assert_equal ["Épée longue +2", 3 + 2 + 2], [attack["name"], attack["to_hit"]]
    assert_match "1d8+5", attack["damage"]
    assert_equal "17", @character.armor_class_shown
  end

  test "an item that requires attunement works only once attuned, and no more than three at a time" do
    ring = give("ring-of-protection")
    amulet = give("amulet-of-health")
    assert_equal ["11", 14], [@character.armor_class_shown, @character.computed_sheet_values[:scores]["constitution"]]

    assert_nil ring.attune(true, limit: 3)
    assert_nil amulet.attune(true, limit: 3)
    @character.reload
    assert_equal ["12", 19], [@character.armor_class_shown, @character.computed_sheet_values[:scores]["constitution"]]

    give("cloak-of-protection").attune(true, limit: 3)
    assert_equal :too_many, give("periapt-of-health").attune(true, limit: 3)
  end

  private

  def give(key, enchantment_key = nil, equipped: false)
    catalog = Catalogs::TableCatalog.new(@game_table).entries("item")
    enchantment = enchantment_key && catalog.find_by!(key: enchantment_key)
    item = InventoryItem.from_entry(catalog.find_by!(key: key), quantity: 1, enchantment: enchantment)
    item.equipped = equipped
    @character.inventory_items << item
    item
  end
end
