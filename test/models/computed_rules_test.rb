require "test_helper"

class ComputedRulesTest < ActiveSupport::TestCase
  JAVASCRIPT_DIRECTORY = Rails.root.join("app/javascript")

  test "the registry lists every computing rule, once, in this order" do
    assert_equal %w[proficiency_by_level ability_modifier initiative_bonus hit_dice_by_class spell_save_dc spell_attack_bonus
                    hit_points_by_level unarmored_armor_class worn_armor_class starting_gold], ComputedRules.keys
  end

  test "an unknown rule works out nothing" do
    assert_nil ComputedRules.find("luck")
    assert_nil ComputedRules.of({ "rule" => "luck" }).value({}, nil)
  end

  test "the rules that read the hit die of the class say so" do
    assert_equal %w[hit_dice_by_class hit_points_by_level], ComputedRules.all.select(&:reads_hit_die?).map(&:key)
  end

  # The page works out the same values while the player types: changing one means changing the other
  test "every rule worked out on the page has its JavaScript twin, listed in the index" do
    index = JAVASCRIPT_DIRECTORY.join("computed_rules/index.js").read

    ComputedRules.all.select(&:live?).each do |rule|
      assert_predicate JAVASCRIPT_DIRECTORY.join("computed_rules/#{rule.key}.js"), :exist?, rule.key
      assert_includes index, "#{rule.key}:", rule.key
    end
  end

  test "every modifier rule has its JavaScript twin, listed in the index" do
    index = JAVASCRIPT_DIRECTORY.join("modifier_rules/index.js").read

    ModifierRules.all.each do |rule|
      assert_predicate JAVASCRIPT_DIRECTORY.join("modifier_rules/#{rule.key}.js"), :exist?, rule.key
      assert_includes index, "#{rule.key}:", rule.key
    end
  end

  test "the template editor says every rule in a sentence, in each language" do
    I18n.available_locales.each do |locale|
      ComputedRules.keys.each do |key|
        assert I18n.exists?("sheet_templates.calculations.rules.#{key}", locale), "#{locale}: #{key}"
      end
      ModifierRules.keys.each do |key|
        assert I18n.exists?("sheet_templates.calculations.modifiers.#{key}", locale), "#{locale}: #{key}"
      end
    end
  end

  test "the lists of the template come from the registries" do
    assert_equal ComputedRules.keys, SheetTemplate::COMPUTED_RULES
    assert_equal ModifierRules.keys, SheetTemplate::MODIFIER_RULES
  end
end
