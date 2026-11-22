require "test_helper"

class SheetTemplatesDuplicatorTest < ActiveSupport::TestCase
  setup do
    @original = EquipmentSpellsTemplateBuilder.create_template
    @game_master = User.create!(email: "mj@example.com", username: "Morgane", password: TEST_PASSWORD)
  end

  test "the copy belongs to the game master, comes from the original, has no language and keeps all its content" do
    copy = I18n.with_locale(:fr) { duplicate }

    assert_equal "Fantasy (copie)", copy.name
    assert_equal @game_master, copy.owner
    assert_equal @original, copy.parent
    assert_nil copy.locale
    SheetTemplates::Duplicator::CONTENT_COLUMNS.each do |column|
      assert_equal @original.public_send(column), copy.public_send(column), column
    end
  end

  test "the catalog is copied line by line, the original keeps its own" do
    copy = duplicate

    assert_equal @original.catalog_entries.pluck(:kind, :key, :name).sort,
                 copy.catalog_entries.pluck(:kind, :key, :name).sort
    assert_equal 11, @original.catalog_entries.count
    copy.catalog_entries.find_by!(key: "fire-bolt").update!(name: "Trait de glace")
    assert_equal "Trait de feu", @original.catalog_entries.find_by!(key: "fire-bolt").name
  end

  test "the name of the copy is cut to the length of a name" do
    @original.update!(name: "x" * SheetTemplate::NAME_MAX_LENGTH)

    assert_equal SheetTemplate::NAME_MAX_LENGTH, duplicate.name.length
  end

  test "the copy is a template the game master may pick for a table" do
    copy = duplicate

    assert_includes SheetTemplate.available_to(@game_master, locale: :en), copy
  end

  private

  def duplicate
    SheetTemplates::Duplicator.new(original: @original, owner: @game_master).call
  end
end
