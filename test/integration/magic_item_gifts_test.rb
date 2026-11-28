require "test_helper"

# The game master gives a magic item from the game room, a magic put on a weapon (« Magie »), and the player attunes
# the character to an item that requires it, from the inventory (« Lié »), three at a time at most
class MagicItemGiftsTest < ActionDispatch::IntegrationTest
  setup do
    template_file = Rails.root.join("db/seeds/sheet_templates/heroic_fantasy.fr.json")
    template = SheetTemplate.find_or_create_by!(JSON.parse(template_file.read(encoding: "UTF-8")))
    %w[items magic].each do |kind|
      Catalogs::Loader.new(Rails.root.join("db/seeds/catalogs/heroic_fantasy_#{kind}.fr.json")).call
    end
    @game_table = GameTable.new(name: "La Forge", starting_level: 1, status: GameTable::READY_STATUS)
    @game_table.use_sheet_template(template)
    @game_table.save!
    @game_master = User.create!(email: "gm@example.com", username: "meneuse", password: TEST_PASSWORD, locale: "fr")
    @player = User.create!(email: "player@example.com", username: "joueur", password: TEST_PASSWORD, locale: "fr")
    @game_table.participations.create!(user: @game_master, role: :game_master)
    participation = @game_table.participations.create!(user: @player, role: :player)
    @character = participation.create_character!(game_table: @game_table, kind: :pc, status: :complete, name: "Brune",
                                                 sheet: { "class" => "Guerrier", "level" => 1, "strength" => 16 })
  end

  test "the game master gives a longsword +1, never a magic that does not go on it" do
    sign_in @game_master
    get game_table_path(@game_table)
    assert_select "select[name=enchantment] option[value=weapon-plus-1]"

    post game_table_item_gift_path(@game_table),
         params: { key: "longsword", character_id: @character.id, quantity: 1, enchantment: "weapon-plus-1" }
    assert_equal "Épée longue +1", @character.inventory_items.last.name

    post game_table_item_gift_path(@game_table),
         params: { key: "dagger", character_id: @character.id, quantity: 1, enchantment: "vorpal-sword" }
    assert_response :not_found
  end

  test "the player attunes to an item that requires it, three at a time" do
    items = %w[ring-of-protection cloak-of-protection amulet-of-health periapt-of-health].map do |key|
      entry = Catalogs::TableCatalog.new(@game_table).entries("item").find_by!(key: key)
      @character.inventory_items.create!(InventoryItem.from_entry(entry, quantity: 1).attributes.compact)
    end
    sign_in @player
    items.first(3).each do |item|
      patch game_table_inventory_item_path(@game_table, item), params: { attuned: "1" }, as: :turbo_stream
    end
    assert_equal [true, true, true], items.first(3).map { |item| item.reload.attuned }

    patch game_table_inventory_item_path(@game_table, items.last), params: { attuned: "1" }, as: :turbo_stream
    assert_not items.last.reload.attuned
    assert_match "Déjà 3 objets liés", response.body
  end
end
