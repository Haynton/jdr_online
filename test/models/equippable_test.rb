require "test_helper"

class EquippableTest < ActiveSupport::TestCase
  ARMOR = { "armor_base" => 11 }.freeze
  SHIELD = { "armor_bonus" => 2 }.freeze
  WEAPON = { "damage_dice" => "1d8" }.freeze

  setup do
    game_table = GameTable.create!(name: "La Crypte", template_snapshot: { "character_fields" => { "fields" => [] } })
    player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD)
    participation = game_table.participations.create!(user: player, role: :player)
    @character = game_table.characters.create!(kind: :pc, participation: participation, name: "Elowen")
  end

  test "an item is an armour, a shield or a weapon by the values its catalog entry gives it" do
    assert item(ARMOR).armor?
    assert item(SHIELD).shield?
    assert item(WEAPON).weapon?
    assert_not item({ "weight" => 1 }).equippable?
  end

  test "one armour and one shield at a time, as many weapons as wanted" do
    leather, chain_mail = [ARMOR, ARMOR].map { |properties| create_item(properties) }
    shield = create_item(SHIELD)
    sword, dagger = [WEAPON, WEAPON].map { |properties| create_item(properties) }

    [leather, shield, sword, dagger].each { |equipped_item| equipped_item.equip(true) }
    chain_mail.equip(true)

    assert_equal [chain_mail, shield, sword, dagger].map(&:id).sort, @character.inventory_items.where(equipped: true).ids.sort
  end

  test "the starting equipment is equipped: its first armour, its first shield, all its weapons" do
    items = [ARMOR, ARMOR, SHIELD, WEAPON, WEAPON, { "weight" => 1 }].map { |properties| item(properties) }

    InventoryItem.equip_starting(items)

    assert_equal [true, false, true, true, true, false], items.map(&:equipped)
  end

  test "a complete character counts in its rules only what its inventory has equipped" do
    create_item(ARMOR).equip(true)
    create_item(SHIELD)

    assert_equal [ARMOR], @character.reload.equipped_item_properties
  end

  private

  def item(properties)
    @character.inventory_items.build(name: "Objet", properties: properties)
  end

  def create_item(properties)
    item(properties).tap(&:save!)
  end
end
