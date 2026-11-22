require "test_helper"

class SpellChoicesTest < ActiveSupport::TestCase
  setup do
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    @game_table = GameTable.create!(name: "La Crypte", sheet_template: sheet_template,
                                    template_snapshot: sheet_template.snapshot)
  end

  test "at level 1, the cantrips and the spells of level 1 of the class, with how many to choose" do
    groups = choices_for("Mage", level: 1).groups

    assert_equal %i[cantrips prepared], groups.map(&:kind)
    assert_equal [2, 2], groups.map(&:allowed_count)
    assert_equal %w[fire-bolt light mage-hand], groups.first.keys.sort
    assert_equal %w[magic-missile shield], groups.last.keys.sort
  end

  test "the spells of a higher level come with the level that can cast them" do
    prepared = choices_for("Mage", level: 3).groups.last

    assert_equal 4, prepared.allowed_count
    assert_includes prepared.keys, "blur"
  end

  test "a class without spellcasting has nothing to choose" do
    assert_empty choices_for("Guerrier", level: 1).groups
    assert_empty choices_for(nil, level: 1).groups
  end

  test "keeps only the spells the class offers, at most as many as allowed" do
    choices = choices_for("Prêtre", level: 1)
    chosen = %w[light fire-bolt bless].map { |key| { "key" => key } }

    assert_equal %w[light bless], choices.keep_offered(chosen).pluck("key")
  end

  test "a copy of a spell keeps its name, level and properties" do
    copy = choices_for("Mage", level: 1).copy_of("magic-missile")

    assert_equal({ "key" => "magic-missile", "name" => "Projectile magique", "level" => 1 },
                 copy.slice("key", "name", "level"))
    assert_nil choices_for("Mage", level: 1).copy_of("bless")
  end

  private

  def choices_for(class_option, level:)
    character = @game_table.characters.build(kind: :pc, sheet: { "class" => class_option, "level" => level }.compact)
    SpellChoices.new(character)
  end
end
