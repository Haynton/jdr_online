require "test_helper"

class WeaponAttacksTest < ActiveSupport::TestCase
  FIELDS = [
    { "key" => "class", "label" => "Classe", "type" => "choice", "options" => %w[Guerrier Magicien],
      "effects" => { "Guerrier" => { "training" => %w[simple-weapons martial-weapons] },
                     "Magicien" => { "training" => %w[simple-weapons] } } },
    { "key" => "level", "label" => "Niveau", "type" => "number" },
    { "key" => "strength", "label" => "Force", "type" => "ability", "modifier" => "half_above_ten" },
    { "key" => "dexterity", "label" => "Dextérité", "type" => "ability", "modifier" => "half_above_ten" },
    { "key" => "proficiency_bonus", "label" => "Maîtrise", "type" => "computed", "rule" => "proficiency_by_level",
      "level_from" => "level" }
  ].freeze
  SETTINGS = { "melee_ability" => "strength", "ranged_ability" => "dexterity", "proficiency" => "proficiency_bonus",
               "training_from" => "class", "two_handed_label" => "à deux mains" }.freeze
  LONGSWORD = { "damage_dice" => "1d8", "versatile_dice" => "1d10", "damage_type" => "tranchants",
                "training" => "martial-weapons" }.freeze

  setup do
    snapshot = { "character_fields" => { "fields" => FIELDS, "weapon_attacks" => SETTINGS },
                 "level_thresholds" => [{ "level" => 1, "experience" => 0, "proficiency_bonus" => 2 }] }
    @game_table = GameTable.create!(name: "La Crypte", template_snapshot: snapshot)
    player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD)
    participation = @game_table.participations.create!(user: player, role: :player)
    @character = @game_table.characters.create!(kind: :pc, participation: participation, name: "Brunhild",
                                                sheet: { "class" => "Guerrier", "level" => 1, "strength" => 16,
                                                         "dexterity" => 14 })
  end

  test "a weapon held attacks with its ability and the proficiency of a trained class, its dice plus the same" do
    hold("Épée longue", LONGSWORD)
    hold("Arc court", { "damage_dice" => "1d6", "damage_type" => "perforants", "ranged" => true,
                        "training" => "simple-weapons" })
    hold("Dague", { "damage_dice" => "1d4", "damage_type" => "perforants", "finesse" => true,
                    "training" => "simple-weapons" })

    assert_equal [{ "name" => "Épée longue", "to_hit" => 5, "damage" => "1d8+3 tranchants" },
                  { "name" => "Épée longue, à deux mains", "to_hit" => 5, "damage" => "1d10+3 tranchants" },
                  { "name" => "Arc court", "to_hit" => 4, "damage" => "1d6+2 perforants" },
                  { "name" => "Dague", "to_hit" => 5, "damage" => "1d4+3 perforants" }], attacks
  end

  test "no proficiency without the training, no two-handed line with a shield, nothing for a weapon in the bag" do
    @character.update!(sheet: @character.sheet.merge("class" => "Magicien"))
    hold("Épée longue", LONGSWORD)
    hold("Bouclier", { "armor_bonus" => 2 })
    @character.inventory_items.create!(name: "Hache", properties: { "damage_dice" => "1d6" })

    assert_equal [{ "name" => "Épée longue", "to_hit" => 3, "damage" => "1d8+3 tranchants" }], attacks
  end

  test "a template without weapon attacks gives none" do
    @game_table.update!(template_snapshot: @game_table.template_snapshot.deep_merge(
      "character_fields" => { "weapon_attacks" => nil }
    ))
    hold("Épée longue", LONGSWORD)

    assert_empty attacks
  end

  private

  def hold(name, properties)
    @character.inventory_items.create!(name: name, properties: properties, equipped: true)
  end

  def attacks
    CharacterSheets::WeaponAttacks.new(@character.reload).call
  end
end
