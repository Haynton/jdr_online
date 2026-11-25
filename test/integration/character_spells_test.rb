require "test_helper"

# The Spells step of the creation of a character: the spells of the class and of the level, chosen, copied into the
# character, checked by the server, shown on the summary
class CharacterSpellsTest < ActionDispatch::IntegrationTest
  setup do
    game_master = User.create!(email: "julien@example.com", username: "Julien", password: TEST_PASSWORD)
    @player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, sheet_template: sheet_template,
                                    template_snapshot: sheet_template.snapshot)
    @game_table.participations.create!(user: game_master, role: :game_master)
    @game_table.participations.create!(user: @player, role: :player)
    sign_in @player
  end

  test "the step offers the cantrips and the spells of the class up to the highest level it can cast" do
    choose_class("Mage")
    get spells_step_path

    assert_response :success
    assert_select "fieldset legend", text: "Sorts mineurs"
    assert_select "fieldset legend", text: "Sorts préparés"
    assert_select "input[type=checkbox][name=?][value=?]", "character[spell_keys][]", "fire-bolt"
    assert_select "input[type=checkbox][name=?][value=?]", "character[spell_keys][]", "magic-missile"
    assert_select "input[value=blur]", count: 0
    assert_select "input[value=bless]", count: 0
    assert_select "p[role=status]", text: "0 sur 2 choisis", count: 2
    assert_select "details summary", text: "Détails"
    assert_select "button[hidden][aria-haspopup=dialog][data-action='spell-details#open']", text: /Détails/
    assert_select "dialog#spell-details-dialog[aria-labelledby=spell-details-dialog-title]", count: 1
    assert_select "p", text: /Vous pourrez en remplacer un à chaque niveau gagné\./
    assert_select "p", text: /Vous pourrez changer toute la liste après chaque repos long\./
    assert_select "#spell-slots-title", text: "Emplacements de sorts"
    assert_select "section[aria-labelledby=spell-slots-title] dt", text: "Niveau 1", count: 1
  end

  test "the filters offer the levels of the spells, concentration and ritual when some have them, and the choice" do
    choose_class("Mage")
    get spells_step_path

    assert_select "[role=group][aria-label=Niveau] button[aria-pressed=false]", count: 2
    assert_select "button[data-group=level][data-value='0']", text: "Sorts mineurs"
    assert_select "[role=group][aria-label='École']", count: 0
    assert_select "button[data-group=casting]", count: 0
    assert_select "button[data-group=chosen]", text: "Mes choix"
    assert_select "li[data-level='1'][data-school=?][data-casting='']", "Évocation", count: 2
  end

  test "the spells chosen are copied into the character and shown on the summary" do
    choose_class("Mage")
    patch spells_step_path, params: { character: { spell_keys: ["", "fire-bolt", "light", "magic-missile"] } }

    spells = character.spells
    assert_equal %w[fire-bolt light magic-missile], spells.pluck("key")
    assert_equal "Projectile magique", spells.last["name"]
    assert_equal "Évocation", spells.last.dig("properties", "school")

    patch game_table_character_step_path(@game_table, "description"), params: { character: { name: "Elara" } }
    follow_redirect!
    assert_select "h3", text: "Sorts mineurs"
    assert_select "h3", text: "Sorts préparés de niveau 1"
    assert_select "li", text: /Projectile magique/
    assert_select "h3#spell-slots-title", text: "Emplacements de sorts"
    assert_select "section[aria-labelledby=spell-slots-title] dd", text: "2"
    assert_select "p", text: "Rendus après un repos long."
  end

  test "a spell not offered, or more spells than allowed, are refused" do
    choose_class("Mage")
    patch spells_step_path, params: { character: { spell_keys: %w[fire-bolt light mage-hand bless] } }

    assert_response :unprocessable_content
    assert_select "[role=alert]", text: /Un sort choisi n'est pas proposé à votre classe et à votre niveau\./
    assert_select "[role=alert]",
                  text: /Trop de sorts choisis dans «[[:space:]]Sorts mineurs[[:space:]]»[[:space:]]: 2 au plus\./
    assert_select "p[role=status][data-invalid]", text: "3 sur 2 choisis"
    assert_empty character.spells
  end

  test "unticking every spell empties the list" do
    choose_class("Mage")
    patch spells_step_path, params: { character: { spell_keys: %w[fire-bolt] } }
    patch spells_step_path, params: { character: { spell_keys: [""] } }

    assert_empty character.spells
  end

  test "changing the class keeps only the spells the new one offers" do
    choose_class("Mage")
    patch spells_step_path, params: { character: { spell_keys: %w[light magic-missile] } }
    choose_class("Prêtre")

    assert_equal %w[light], character.spells.pluck("key")
  end

  private

  # The class, then the equipment step, which comes before the spells
  def choose_class(option)
    patch game_table_character_step_path(@game_table, "class"), params: { character: { sheet: { class: option } } }
    patch game_table_character_step_path(@game_table, "equipment"), params: { character: { sheet: {} } }
  end

  def spells_step_path
    game_table_character_step_path(@game_table, "spells")
  end

  def character
    @player.participations.find_by!(game_table: @game_table).reload.character
  end
end
