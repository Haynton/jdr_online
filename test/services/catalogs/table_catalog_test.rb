require "test_helper"

# What a table offers: the catalog of its template, less what it turned off, its own copies in place of the originals,
# plus what it added
class TableCatalogTest < ActiveSupport::TestCase
  setup do
    @sheet_template = EquipmentSpellsTemplateBuilder.create_template
    @game_table = GameTable.create!(name: "La Crypte", sheet_template: @sheet_template,
                                    template_snapshot: @sheet_template.snapshot)
    @template_spells = @sheet_template.catalog_entries.spells
  end

  test "a table that changed nothing offers the catalog of its template" do
    assert_equal @template_spells.pluck(:key).sort, spell_keys
  end

  test "an entry turned off for the table is not offered, the template keeps it" do
    @game_table.update!(disabled_catalog_keys: { "spell" => ["shield"] })

    assert_not_includes spell_keys, "shield"
    assert @template_spells.exists?(key: "shield")
  end

  test "the copy of an entry changed for the table takes the place of the original" do
    original = @template_spells.find_by!(key: "magic-missile")
    @game_table.catalog_entries.create!(kind: "spell", key: original.key, name: "Projectile magique amélioré",
                                        properties: original.properties)

    offered = catalog.entries("spell").where(key: "magic-missile")
    assert_equal ["Projectile magique amélioré"], offered.pluck(:name)
    assert_equal "Projectile magique", original.reload.name
  end

  test "an entry added by the game master is offered, to that table only" do
    added = @game_table.catalog_entries.create!(kind: "spell", key: "home-spell", name: "Sort maison",
                                                properties: @template_spells.first.properties)
    other_table = GameTable.create!(name: "Les Marches du Nord", sheet_template: @sheet_template,
                                    template_snapshot: @sheet_template.snapshot)

    assert_includes spell_keys, added.key
    assert_not_includes Catalogs::TableCatalog.new(other_table).entries("spell").pluck(:key), added.key
  end

  test "the spells offered to a character come from the catalog of its table" do
    @game_table.update!(disabled_catalog_keys: { "spell" => ["shield"] })
    character = @game_table.characters.build(kind: :pc, sheet: { "class" => "Mage", "level" => 1 })

    prepared = CharacterSheets::SpellChoices.new(character).groups.last
    assert_equal ["magic-missile"], prepared.keys
  end

  test "an entry belongs to a template or to a table, never both, never neither" do
    both = CatalogEntry.new(kind: "spell", key: "both", name: "Les deux", sheet_template: @sheet_template,
                            game_table: @game_table)
    neither = CatalogEntry.new(kind: "spell", key: "neither", name: "Aucun")

    assert both.tap(&:validate).errors.of_kind?(:base, :one_catalog)
    assert neither.tap(&:validate).errors.of_kind?(:base, :one_catalog)
  end

  private

  def catalog
    Catalogs::TableCatalog.new(@game_table)
  end

  def spell_keys
    catalog.entries("spell").pluck(:key).sort
  end
end
