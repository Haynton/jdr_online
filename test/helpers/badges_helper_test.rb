require "test_helper"

class BadgesHelperTest < ActionView::TestCase
  test "the game master badge uses the tonal gold, never the solid button color" do
    assert_includes badge_classes(:game_master), "bg-primary-soft text-primary-soft-ink"
    assert_not_includes badge_classes(:game_master).split, "bg-primary"
  end

  test "the player badge uses the success colors" do
    assert_includes badge_classes(:player), "bg-success-bg text-success-ink"
  end

  test "every badge has an inner ring of its text color so the pill shows on a card" do
    assert_includes badge_classes(:game_master), "ring-1 ring-inset ring-primary-soft-ink/50"
    assert_includes badge_classes(:player), "ring-1 ring-inset ring-success-ink/50"
  end

  test "every badge is a small uppercase pill" do
    %i[game_master player].each do |variant|
      assert_includes badge_classes(variant), "rounded-full px-2.5 py-1"
      assert_includes badge_classes(variant), "text-[11px] leading-4 font-bold tracking-wide uppercase"
    end
  end

  test "an unknown variant fails loudly" do
    assert_raises(KeyError) { badge_classes(:spectator) }
  end
end
