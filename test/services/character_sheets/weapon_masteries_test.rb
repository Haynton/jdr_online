require "test_helper"

# The fighting style and the weapon masteries a class gives at a level, the kinds of weapons it offers (by category or
# by kind, melee only for a barbarian), the server refusing more, and their effects on the attacks
class WeaponMasteriesTest < ActiveSupport::TestCase
  setup do
    @game_table = GameTable.create!(name: "La Crypte", template_snapshot: WeaponMasteryTemplate.snapshot)
    WeaponMasteryTemplate.add_weapons(@game_table)
    player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD)
    participation = @game_table.participations.create!(user: player, role: :player)
    @character = @game_table.characters.create!(kind: :pc, participation: participation, name: "Brunhild",
                                                sheet: { "class" => "Guerrier", "strength" => 14, "dexterity" => 14 })
  end

  test "a class offers its count of kinds, those it is trained in, melee only for a barbarian, and its styles" do
    choices = @character.weapon_mastery_choices
    assert_equal [2, %w[daggers longbows longswords]], [choices.allowed_count, choices.offered_kinds.map(&:key).sort]
    assert_equal %w[archery defense], choices.offered_styles.map(&:key)
    assert_equal ["Épées longues", "Sape", "Désavantage."],
                 choices.offered_kinds.find { |kind| kind.key == "longswords" }.to_h.values_at(:label, :mastery, :rule)

    @character.sheet = @character.sheet.merge("class" => "Barbare")
    assert_equal %w[daggers longswords], @character.weapon_mastery_choices.offered_kinds.map(&:key).sort

    @character.sheet = @character.sheet.merge("class" => "Magicien")
    assert_not_predicate @character.weapon_mastery_choices, :offered?
  end

  test "the server refuses more kinds than the class gives, a kind or a style it does not offer" do
    @character.choose_weapon_masteries("defense", %w[longswords longbows daggers])
    assert @character.tap(&:validate).errors.of_kind?(:weapon_masteries, :too_many)

    @character.sheet = @character.sheet.merge("class" => "Magicien")
    @character.choose_weapon_masteries("archery", ["longswords"])
    errors = @character.tap(&:validate).errors
    assert errors.of_kind?(:fighting_style, :not_offered)
    assert errors.of_kind?(:weapon_masteries, :not_offered)
  end

  test "Archery adds 2 to a ranged weapon, and a kind mastered names its property on the attack" do
    @character.update!(fighting_style: "archery", weapon_masteries: ["longbows"])
    @character.inventory_items.create!(name: "Arc long", properties: WeaponMasteryTemplate::WEAPONS["longbow"], equipped: true)
    @character.inventory_items.create!(name: "Épée longue", properties: WeaponMasteryTemplate::WEAPONS["longsword"], equipped: true)

    attacks = CharacterSheets::WeaponAttacks.new(@character.reload).call
    bow, sword = attacks.partition { |attack| attack["name"] == "Arc long" }.map(&:first)

    assert_equal [2 + 2, "Ralentissement"], bow.values_at("to_hit", "mastery")
    assert_nil sword["mastery"]
  end
end
