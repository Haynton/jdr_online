require "test_helper"

# The feats of the heroic fantasy (SRD 5.2.1): those a character may take at a level that improves its abilities (their
# level, their ability minimum, the effect they need, an epic boon at 19), and what they do once taken: points to the
# abilities kept apart, the proficiency to the initiative of Alert, the fighting style of a fighting style feat
class FeatsTest < ActiveSupport::TestCase
  setup do
    template_file = Rails.root.join("db/seeds/sheet_templates/heroic_fantasy.fr.json")
    template = SheetTemplate.find_or_create_by!(JSON.parse(template_file.read(encoding: "UTF-8")))
    Catalogs::Loader.new(Rails.root.join("db/seeds/catalogs/heroic_fantasy_features.fr.json")).call
    Catalogs::Loader.new(Rails.root.join("db/seeds/catalogs/heroic_fantasy_spells.fr.json")).call
    @game_table = GameTable.new(name: "La Crypte", starting_level: 4)
    @game_table.use_sheet_template(template)
    @game_table.save!
    player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD)
    @participation = @game_table.participations.create!(user: player, role: :player)
  end

  test "a level 4 offers the improvement, the grappler with 13 in Strength, fighting styles to a class that has some" do
    fighter = build_character("class" => "Guerrier", "subclass" => "Champion", "strength" => 13, "dexterity" => 10)
    keys = fighter.feat_list.offered(level: 4).map(&:key)
    assert_includes keys, "ability-score-improvement"
    assert_includes keys, "grappler"
    assert_includes keys, "defense"
    assert_not_includes keys, "boon-of-fate"

    wizard = build_character("class" => "Magicien", "strength" => 8, "dexterity" => 12)
    keys = wizard.feat_list.offered(level: 4).map(&:key)
    assert_not_includes keys, "grappler"
    assert_not_includes keys, "defense"
    assert_includes wizard.feat_list.offered(level: 19, epic: true).map(&:key), "boon-of-spell-recall"
  end

  test "a feat taken adds its points apart from the score, and is not offered again unless it repeats" do
    character = build_character("class" => "Guerrier", "strength" => 15, "dexterity" => 13,
                                "feats" => [{ "key" => "grappler", "level" => 4, "abilities" => { "strength" => 1 } }])
    assert_equal [15, 16], [character.sheet["strength"], character.computed_sheet_values[:scores]["strength"]]
    assert_not_includes character.feat_list.offered(level: 8).map(&:key), "grappler"
    assert_includes character.feat_list.offered(level: 8).map(&:key), "ability-score-improvement"
  end

  test "Alert adds the proficiency to the initiative, a fighting style feat its effect" do
    criminal = build_character("class" => "Roublard", "background" => "Criminel", "dexterity" => 14)
    assert_equal 2 + 2, criminal.computed_sheet_values[:values]["initiative"]

    fighter = build_character("class" => "Guerrier", "feats" => [{ "key" => "archery", "level" => 4 }])
    assert_equal 2, fighter.fighting_style_effects["ranged_attack_bonus"]
  end

  test "the level up takes a feat with its points, or the skills of Skilled" do
    character = build_character("class" => "Guerrier", "subclass" => "Champion", "level" => 3, "strength" => 13)
    character.update_columns(level_up_to: 4)
    level_up = LevelUp.new(character: character, feat_key: "grappler", ability_increases: { "strength" => "1" })
    assert level_up.save, level_up.errors.full_messages.to_sentence
    assert_equal [{ "key" => "grappler", "level" => 4, "abilities" => { "strength" => 1 } }], character.reload.feats

    character.update_columns(level_up_to: 5, feats: [], sheet: character.sheet.merge("level" => 3))
    character.update_columns(level_up_to: 4)
    level_up = LevelUp.new(character: character.reload, feat_key: "skilled", feat_skill_keys: %w[arcana])
    assert_not level_up.valid?
    level_up.feat_skill_keys = %w[arcana history nature]
    assert level_up.save, level_up.errors.full_messages.to_sentence
    assert_equal [true, true, true], character.reload.sheet.values_at("arcana", "history", "nature")
  end

  test "the acolyte picks the spells of its origin feat in the cleric list, copied apart from its class spells" do
    acolyte = build_character("class" => "Guerrier", "background" => "Acolyte")
    acolyte.checks_feat_spells = true
    acolyte.checks_feat_spell_picks = true
    acolyte.choose_origin_feat_spells({ "spell_ability" => "wisdom", "cantrips" => %w[guidance] })
    assert acolyte.tap(&:validate).errors.of_kind?(:feats, :cantrips)

    acolyte.choose_origin_feat_spells({ "spell_ability" => "wisdom", "cantrips" => %w[guidance sacred-flame],
                                        "spell" => "bless" })
    assert acolyte.valid?, acolyte.errors.full_messages.to_sentence
    assert_equal %w[bless guidance sacred-flame], acolyte.spells.pluck("key").sort
    assert_equal ["magic-initiate"], acolyte.spells.pluck("feat").uniq

    acolyte.sheet = acolyte.sheet.merge("background" => "Soldat")
    acolyte.keep_offered_origin_feat_spells
    assert_empty acolyte.spells
  end

  test "Magic Initiate taken at a level gained asks a list and its spells, the other lists left out" do
    character = build_character("class" => "Guerrier", "subclass" => "Champion", "level" => 3)
    character.update_columns(level_up_to: 4)
    level_up = LevelUp.new(character: character, feat_key: "magic-initiate", feat_spells: {
      "spell_list" => "Magicien",
      "by_list" => { "Magicien" => { "spell_ability" => "intelligence", "cantrips" => %w[light mage-hand], "spell" => "shield" },
                     "Clerc" => { "cantrips" => %w[guidance] } }
    })
    assert level_up.save, level_up.errors.full_messages.to_sentence
    assert_equal %w[light mage-hand shield], character.reload.spells.pluck("key").sort
    assert_equal "Magicien", character.feats.last["spell_list"]
  end

  test "Magic Initiate taken again takes another list, and a spell known already is refused" do
    acolyte = build_character("class" => "Guerrier", "background" => "Acolyte", "species" => "Humain",
                              "feats" => [{ "key" => "magic-initiate", "source" => "background", "spell_list" => "Clerc",
                                            "spell_ability" => "wisdom", "cantrips" => %w[guidance sacred-flame],
                                            "spell" => "bless" }])
    settings = acolyte.feat_spells.open_settings(acolyte.feat_list.find("magic-initiate").effects["spell_picks"],
                                                 source: CharacterFeats::SPECIES_SOURCE)
    assert_equal %w[Druide Magicien], settings["lists"]
    assert_equal "Initié à la magie (Acolyte)", acolyte.feat_spells.known_elsewhere(except: "species")["guidance"]

    acolyte.checks_species_feat = true
    acolyte.checks_feat_spell_picks = true
    acolyte.choose_species_feat({ "key" => "magic-initiate", "feat_spells" => {
      "spell_list" => "Druide", "by_list" => { "Druide" => { "spell_ability" => "wisdom", "cantrips" => %w[guidance druidcraft],
                                                             "spell" => "cure-wounds" } }
    } })
    assert acolyte.tap(&:validate).errors.of_kind?(:feats, :spell_known)
  end

  test "a spell picked for the class and given by a feat is refused" do
    cleric = build_character("class" => "Clerc", "background" => "Acolyte", "level" => 1,
                             "feats" => [{ "key" => "magic-initiate", "source" => "background", "spell_list" => "Clerc",
                                           "spell_ability" => "wisdom", "cantrips" => %w[guidance sacred-flame],
                                           "spell" => "bless" }])
    cleric.choose_spells(%w[guidance])
    assert cleric.tap(&:validate).errors.of_kind?(:spells, :spell_known_twice)
  end

  test "a level gained replaces a spell of a feat by another of the same level, not by one known already" do
    character = build_character("class" => "Guerrier", "subclass" => "Champion", "level" => 4,
                                "feats" => [{ "key" => "magic-initiate", "level" => 4, "spell_list" => "Magicien",
                                              "spell_ability" => "intelligence", "cantrips" => %w[light mage-hand],
                                              "spell" => "shield" }])
    character.update_columns(level_up_to: 5)
    refused = LevelUp.new(character: character, feat_spell_swaps: { "level-4" => { "from" => "light", "to" => "sleep" } })
    assert refused.tap(&:validate).errors.of_kind?(:feat_spell_swaps, :not_allowed)
    known = LevelUp.new(character: character, feat_spell_swaps: { "level-4" => { "from" => "light", "to" => "mage-hand" } })
    assert_not known.valid?

    level_up = LevelUp.new(character: character, feat_spell_swaps: { "level-4" => { "from" => "light", "to" => "minor-illusion" } })
    assert level_up.save, level_up.errors.full_messages.to_sentence
    assert_equal %w[minor-illusion mage-hand], character.reload.feats.first["cantrips"]
    assert_includes character.spells.pluck("key"), "minor-illusion"
  end

  test "a table without origin feats gives no feat by the background, none to pick for the human" do
    @game_table.update!(origin_feats: false)
    acolyte = build_character("class" => "Guerrier", "background" => "Acolyte", "species" => "Humain")
    assert_nil acolyte.origin_feat_spells
    assert_nil acolyte.feat_choice_settings
    assert_empty acolyte.feat_list.taken_keys
  end

  test "a table without feats at the levels offers only the improvement" do
    @game_table.update!(level_feats: false)
    character = build_character("class" => "Guerrier", "subclass" => "Champion", "level" => 3, "strength" => 13)
    character.update_columns(level_up_to: 4)
    assert_equal ["ability-score-improvement"], LevelUp.new(character: character).offered_feats.map(&:key)
  end

  test "what an option gives stays ticked, unless the table lets the players change it" do
    character = build_character("class" => "Barbare", "background" => "Soldat", "level" => 1)
    character.update_columns(sheet: character.sheet.merge("strength_save" => false, "intimidation" => false))
    character.keep_given_ticked
    assert_equal [true, true], character.sheet.values_at("strength_save", "intimidation")
    assert character.given_locked?("intimidation")

    @game_table.update!(players_change_given_choices: true)
    character.update_columns(sheet: character.sheet.merge("intimidation" => false))
    character.reload.keep_given_ticked
    assert_equal false, character.sheet["intimidation"]
    assert_not character.given_locked?("intimidation")
  end

  test "Magic Initiate is one card per list, the list taken greyed, and the card picked gives its list" do
    acolyte = build_character("class" => "Guerrier", "background" => "Acolyte", "species" => "Humain",
                              "feats" => [{ "key" => "magic-initiate", "source" => "background", "spell_list" => "Clerc" }])
    cards = CharacterSheets::FeatCards.new(acolyte, source: "species").cards([acolyte.feat_list.find("magic-initiate")])
    names = I18n.with_locale(:fr) { cards.map(&:name) }
    assert_equal ["Initié à la magie : Clerc", "Initié à la magie : Druide", "Initié à la magie : Magicien"], names
    assert_equal [true, false, false], cards.map(&:taken?)
    assert_equal "Nature, soins, bêtes et éléments.", cards.second.list_description

    acolyte.choose_species_feat({ "key" => "magic-initiate~Druide", "feat_spells" => {
      "by_list" => { "Druide" => { "spell_ability" => "wisdom", "cantrips" => %w[druidcraft produce-flame], "spell" => "cure-wounds" } }
    } })
    assert_equal "Druide", acolyte.species_feat_entry["spell_list"]
  end

  private

  def build_character(values)
    @participation.character&.destroy
    feats = values.delete("feats") || []
    @participation.reload.create_character!(game_table: @game_table, kind: :pc, status: :complete, name: "Vex",
                                            sheet: { "level" => 4 }.merge(values), feats: feats)
  end
end
