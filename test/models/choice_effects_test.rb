require "test_helper"

class ChoiceEffectsTest < ActiveSupport::TestCase
  JAVASCRIPT_DIRECTORY = Rails.root.join("app/javascript")
  FIELDS_BY_KEY = {
    "athletics" => { "label" => "Athlétisme" }, "history" => { "label" => "Histoire" },
    "wisdom" => { "label" => "Sagesse" }, "intelligence" => { "label" => "Intelligence" },
    "speed" => { "label" => "Vitesse" }
  }.freeze

  test "the registry lists every effect, once, in the order of the summary of the choices" do
    assert_equal %w[hit_die hit_points_per_level proficient skill_choices spellcasting always_prepared_spells
                    ability_bonus_choices origin_feat set unarmored_defense unarmored_defense_without_shield training tools features_by_level traits
                    starting_equipment], ChoiceEffects.keys
    assert_equal ChoiceEffects.keys, SheetTemplate::CHOICE_EFFECTS
    assert_nil ChoiceEffects.find("flight")
  end

  test "an effect names the fields of the type it declares" do
    assert_equal %w[athletics], ChoiceEffects.find("proficient").target_keys(["athletics"])
    assert_equal "bonus", ChoiceEffects.find("skill_choices").target_type
    assert_equal %w[wisdom], ChoiceEffects.find("spellcasting").target_keys({ "ability" => "wisdom" })
    assert_nil ChoiceEffects.find("set").target_type
  end

  test "each effect a player can read says what it brings, in French" do
    I18n.with_locale(:fr) do
      assert_equal [["Dé de vie", "d8"]], facts("hit_die", 8)
      assert_equal [["Maîtrises", "Athlétisme et Histoire"]], facts("proficient", %w[athletics history])
      assert_equal [["Compétences", "2 au choix"]], facts("skill_choices", { "count" => 2, "from" => [] })
      assert_equal [["Caractéristique des sorts", "Sagesse"]], facts("spellcasting", { "ability" => "wisdom" })
      assert_equal [["Vitesse", "10,5"]], facts("set", { "speed" => 10.5 })
      assert_empty facts("training", ["light_armor"])
      assert_equal [["Caractéristiques augmentées", "Sagesse et Intelligence"]],
                   facts("ability_bonus_choices", %w[wisdom intelligence])
    end
  end

  test "the hit points per level and the named features of a subclass are said, each feature with its level" do
    I18n.with_locale(:fr) do
      assert_equal [["Points de vie", "+1 par niveau"]], facts("hit_points_per_level", 1)
      features = { "6" => [{ "key" => "rage", "name" => "Rage aveugle" }],
                   "3" => [{ "key" => "frenzy", "name" => "Frénésie" }, { "key" => "fury", "name" => "Fureur" }] }
      assert_equal [["Niveau 3", "Frénésie et Fureur", 3], ["Niveau 6", "Rage aveugle", 6]],
                   facts("features_by_level", features)
      assert_empty facts("features_by_level", { "3" => ["cleric-subclass"] })
    end
  end

  test "the effects given level by level are checked: levels 1 to 20, lists of keys" do
    always_prepared = ChoiceEffects.find("always_prepared_spells")

    assert_empty always_prepared.value_errors({ "3" => %w[aid bless], "5" => ["revivify"] })
    assert_equal %w[aid bless revivify], always_prepared.spell_keys({ "5" => ["revivify"], "3" => %w[aid bless] }, 5)
    assert_equal %w[aid bless], always_prepared.spell_keys({ "5" => ["revivify"], "3" => %w[aid bless] }, 4)
    assert_equal [:invalid_level_entries], always_prepared.value_errors({ "21" => ["aid"] }).map(&:first)
    assert_equal [:invalid_level_entries], always_prepared.value_errors(["aid"]).map(&:first)
    assert_equal [:invalid_level_entries],
                 ChoiceEffects.find("features_by_level").value_errors({ "3" => [{ "key" => "frenzy" }] }).map(&:first)
    assert_equal [:unknown_effect_value], ChoiceEffects.find("hit_points_per_level").value_errors("1").map(&:first)
  end

  test "the abilities a background raises are said with the rule of the game, the help of the bonus field" do
    fields_by_key = FIELDS_BY_KEY.merge(
      "ability_bonuses" => { "type" => "ability_bonuses", "help" => "Répartissez +2 et +1, ou +1 à chacune." }
    )

    I18n.with_locale(:fr) do
      assert_equal [["Caractéristiques augmentées", "Sagesse et Intelligence (Répartissez +2 et +1, ou +1 à chacune)"]],
                   ChoiceEffects.find("ability_bonus_choices").facts(%w[wisdom intelligence], fields_by_key)
    end
  end

  test "an effect without a value says nothing" do
    ChoiceEffects.all.each { |effect| assert_empty effect.facts(nil, FIELDS_BY_KEY), effect.key }
  end

  # The page applies them while the player picks: changing one means changing the other
  test "every effect applied on the page has its JavaScript twin, listed in the index" do
    index = JAVASCRIPT_DIRECTORY.join("choice_effects/index.js").read

    ChoiceEffects.all.select(&:live?).each do |effect|
      assert_predicate JAVASCRIPT_DIRECTORY.join("choice_effects/#{effect.key}.js"), :exist?, effect.key
      assert_includes index, "import #{effect.key} from", effect.key
    end
  end

  private

  def facts(effect_key, value)
    ChoiceEffects.find(effect_key).facts(value, FIELDS_BY_KEY)
  end
end
