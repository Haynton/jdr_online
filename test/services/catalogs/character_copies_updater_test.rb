require "test_helper"

# The spells and items the game master changed for a table, applied to the characters already made
class CharacterCopiesUpdaterTest < ActiveSupport::TestCase
  setup do
    game_master = User.create!(email: "gm@example.com", username: "maitre", password: TEST_PASSWORD)
    @game_table = GameTableCreator.new(user: game_master, attributes: { name: "La Crypte" },
                                       sheet_template: EquipmentSpellsTemplateBuilder.create_template).call
    @character = character_holding(spell_key: "shield", item_key: "dagger", item_name: "Dague rouillée")
  end

  test "a character holding the template's version is not counted" do
    assert_empty updater.characters_to_update
    assert_equal 0, updater.call
  end

  test "the table's version of a spell replaces the character's copy" do
    copy_for_table("spell", "shield", name: "Bouclier de givre", description: "Un mur de glace.")

    assert_equal [@character], updater.characters_to_update
    assert_equal 1, updater.call
    spell = @character.reload.spells.first
    assert_equal ["shield", "Bouclier de givre", "Un mur de glace."], spell.values_at("key", "name", "description")
    assert_empty updater.characters_to_update
  end

  test "an item takes the table's name and values, keeping its note" do
    copy_for_table("item", "dagger", name: "Lame", description: "Courte et fine.")

    updater.call

    item = @character.inventory_items.first.reload
    assert_equal ["Lame rouillée", "Courte et fine."], [item.name, item.description]
  end

  test "an entry turned off stays on the sheets that have it" do
    @game_table.update!(disabled_catalog_keys: { "spell" => ["shield"] })

    assert_equal 0, updater.call
    assert_equal ["shield"], @character.reload.spells.pluck("key")
  end

  private

  def updater
    Catalogs::CharacterCopiesUpdater.new(@game_table)
  end

  def template_entry(kind, key)
    @game_table.sheet_template.catalog_entries.find_by!(kind: kind, key: key)
  end

  def copy_for_table(kind, key, **changes)
    original = template_entry(kind, key)
    @game_table.catalog_entries.create!(kind: kind, key: key, name: original.name, description: original.description,
                                        properties: original.properties, **changes)
  end

  def character_holding(spell_key:, item_key:, item_name:)
    player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD)
    participation = @game_table.participations.create!(user: player, role: "player")
    spell = template_entry("spell", spell_key)
    character = @game_table.characters.create!(kind: "pc", participation: participation, name: "Lia", status: "draft")
    # As copied when it was made (CharacterSheets::SpellChoices#copy_of), whatever its class
    character.update_columns(spells: [{ "key" => spell.key, "name" => spell.name, "level" => spell.level,
                                        "description" => spell.description, "properties" => spell.properties }])
    item = template_entry("item", item_key)
    character.inventory_items.create!(key: item.key, name: item_name, description: item.description,
                                      properties: item.properties, quantity: 1)
    character
  end
end
