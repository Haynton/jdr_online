require "test_helper"

# The spellbook of the wizard at the Spells step (SRD 5.2.1): 6 level 1 spells written in it, 4 of them prepared; a
# spell prepared outside the book, or a seventh spell, is refused
class WizardSpellbookTest < ActionDispatch::IntegrationTest
  BOOK = %w[magic-missile shield sleep mage-armor detect-magic feather-fall].freeze

  setup do
    template_file = Rails.root.join("db/seeds/sheet_templates/heroic_fantasy.fr.json")
    template = SheetTemplate.find_or_create_by!(JSON.parse(template_file.read(encoding: "UTF-8")))
    Catalogs::Loader.new(Rails.root.join("db/seeds/catalogs/heroic_fantasy_spells.fr.json")).call
    @game_table = GameTable.new(name: "La Tour", starting_level: 1, status: GameTable::READY_STATUS, origin_feats: false)
    @game_table.use_sheet_template(template)
    @game_table.save!
    @player = User.create!(email: "player@example.com", username: "joueur", password: TEST_PASSWORD, locale: "fr")
    participation = @game_table.participations.create!(user: @player, role: :player)
    @character = participation.create_character!(game_table: @game_table, kind: :pc, status: :draft, creation_step: "spells",
                                                 sheet: { "class" => "Magicien", "background" => "Soldat", "level" => 1 })
  end

  test "the wizard writes 6 spells in its spellbook and prepares 4 of them" do
    sign_in @player
    get game_table_character_step_path(@game_table, "spells")
    assert_select "input[name='character[spellbook_keys][]'][value=?]", "magic-missile"
    assert_select "input[name='character[spell_keys][]'][data-prepared-box][value=?]", "magic-missile"
    assert_select "p[data-count-for=book]", text: "Grimoire : 0 sur 6"

    send_spells(book: BOOK, prepared: BOOK.first(4))
    @character.reload
    assert_equal BOOK.sort, @character.spellbook.pluck("key").sort
    assert_equal (BOOK.first(4) + %w[light fire-bolt mage-hand]).sort, @character.spells.pluck("key").sort
  end

  test "a spell prepared outside the book, or a seventh spell in it, is refused" do
    sign_in @player
    send_spells(book: BOOK.first(5), prepared: %w[magic-missile burning-hands])
    assert_response :unprocessable_content
    assert_select "p", text: /n'est pas dans votre Grimoire/

    send_spells(book: BOOK + %w[burning-hands], prepared: BOOK.first(2))
    assert_response :unprocessable_content
    assert_select "p", text: "Trop de sorts dans « Grimoire » : 6 au plus."
  end

  test "a level gained writes as many spells in the book as the class says, among those not written yet" do
    send_spells_as_saved
    @character.update_columns(status: "complete", name: "Mirabelle", level_up_to: 2, sheet: @character.sheet.merge("arcana" => true))
    level_up = LevelUp.new(character: @character.reload, hit_point_choice: "average", expertise_keys: %w[arcana],
                           spellbook_keys: %w[magic-missile])
    assert_not level_up.valid?
    assert level_up.errors.of_kind?(:spellbook_keys, :not_picked)

    level_up.spellbook_keys = %w[burning-hands thunderwave]
    assert level_up.save, level_up.errors.full_messages.to_sentence
    assert_equal 8, @character.reload.spellbook.size
  end

  test "in the game room, the wizard prepares only from its book, and copies a found spell for its gold" do
    send_spells_as_saved
    @character.update_columns(status: "complete", name: "Mirabelle", sheet: @character.sheet.merge("gold" => 60))
    sign_in @player
    get edit_game_table_spell_choice_path(@game_table)
    assert_select "input[name='character[spell_keys][]'][data-prepared-box][value=?]", "sleep"
    assert_select "input[name='character[spell_keys][]'][value=?]", "burning-hands", count: 0
    assert_select "option[value=?]", "burning-hands", text: "Mains brûlantes · niveau 1 · 50 po"

    post game_table_spellbook_copy_path(@game_table), params: { spell_key: "burning-hands" }
    @character.reload
    assert_includes @character.spellbook.pluck("key"), "burning-hands"
    assert_equal 10, @character.sheet["gold"]
    assert_equal "spell_copied", @game_table.chat_messages.last.event_key

    post game_table_spellbook_copy_path(@game_table), params: { spell_key: "thunderwave" }
    assert_response :unprocessable_content
    assert_not_includes @character.reload.spellbook.pluck("key"), "thunderwave"
  end

  test "a spell copied in the game does not fill the book: the wizard still changes its spells and gains a level" do
    send_spells_as_saved
    @character.update_columns(status: "complete", name: "Mirabelle", sheet: @character.sheet.merge("gold" => 60))
    sign_in @player
    post game_table_spellbook_copy_path(@game_table), params: { spell_key: "burning-hands" }
    assert @character.reload.valid?, @character.errors.full_messages.to_sentence

    patch game_table_spell_choice_path(@game_table),
          params: { character: { spell_keys: %w[light fire-bolt mage-hand burning-hands] + BOOK.first(3) } }
    assert_includes @character.reload.spells.pluck("key"), "burning-hands"

    @character.update_columns(level_up_to: 2, sheet: @character.sheet.merge("arcana" => true))
    level_up = LevelUp.new(character: @character.reload, hit_point_choice: "average", expertise_keys: %w[arcana],
                           spellbook_keys: %w[thunderwave color-spray])
    assert level_up.save, level_up.errors.full_messages.to_sentence
    assert_equal 9, @character.reload.spellbook.size
  end

  private

  def send_spells_as_saved
    @character.choose_spellbook(BOOK)
    @character.choose_spells(%w[light fire-bolt mage-hand] + BOOK.first(4))
    @character.save!(validate: false)
  end

  def send_spells(book:, prepared:)
    patch game_table_character_step_path(@game_table, "spells"),
          params: { character: { spellbook_keys: book, spell_keys: %w[light fire-bolt mage-hand] + prepared } }
  end
end
