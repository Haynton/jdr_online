require "test_helper"

# The features, traits and feats a character has: those its options name, up to its level, with their name and summary
# from the catalog of its table (the table's own copy in place of the template's), the name the option gives otherwise
class CharacterFeaturesTest < ActiveSupport::TestCase
  FIELDS = [
    { "key" => "level", "label" => "Niveau", "type" => "number", "from_table" => "starting_level" },
    { "key" => "class", "label" => "Classe", "type" => "choice", "options" => %w[Barbare],
      "effects" => { "Barbare" => { "features_by_level" => {
        "1" => ["rage"], "4" => ["asi"], "5" => ["extra-attack"], "8" => ["asi"]
      } } } },
    { "key" => "subclass", "label" => "Sous-classe", "type" => "choice", "options" => ["Voie du Berserker"],
      "effects" => { "Voie du Berserker" => { "features_by_level" => {
        "3" => [{ "key" => "frenzy", "name" => "Frénésie" }]
      } } } },
    { "key" => "background", "label" => "Historique", "type" => "choice", "options" => %w[Criminel],
      "effects" => { "Criminel" => { "origin_feat" => { "key" => "alert", "name" => "Vigilance" } } } },
    { "key" => "species", "label" => "Espèce", "type" => "choice", "options" => %w[Nain],
      "effects" => { "Nain" => { "traits" => ["darkvision-120"] } } }
  ].freeze

  setup do
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    { "rage" => "Rage", "extra-attack" => "Attaque supplémentaire", "alert" => "Vigilance",
      "darkvision-120" => "Vision dans le noir" }.each do |key, name|
      sheet_template.catalog_entries.create!(kind: "feature", key: key, name: name, description: "#{name}, en bref.")
    end
    @game_table = GameTable.create!(name: "La Crypte", sheet_template: sheet_template, starting_level: 3,
                                    template_snapshot: { "character_fields" => { "fields" => FIELDS } })
    player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD)
    participation = @game_table.participations.create!(user: player, role: :player)
    @character = @game_table.characters.create!(
      kind: :pc, participation: participation, name: "Brunhild",
      sheet: { "class" => "Barbare", "subclass" => "Voie du Berserker", "background" => "Criminel",
               "species" => "Nain" }
    )
  end

  test "each option picked gives its features up to the level, with the name and the summary of the catalog" do
    groups = CharacterSheets::Features.new(@character).call

    picked = groups.map { |group| [group.label, group.option] }
    assert_equal [%w[Classe Barbare], ["Sous-classe", "Voie du Berserker"], %w[Historique Criminel], %w[Espèce Nain]],
                 picked
    rage = groups.first.features.sole
    assert_equal ["Rage", "Rage, en bref.", :feature, 1], [rage.name, rage.description, rage.kind, rage.level]
    assert_equal [:feat, "Vigilance"], groups.third.features.sole.to_h.values_at(:kind, :name)
    assert_equal :trait, groups.fourth.features.sole.kind
  end

  test "a feature the catalog lacks keeps the name its option gives, without a summary" do
    frenzy = CharacterSheets::Features.new(@character).call.second.features.sole

    assert_equal ["Frénésie", nil, 3], [frenzy.name, frenzy.description, frenzy.level]
  end

  test "a higher level reaches more features, each once, and the copy of the table replaces the template's summary" do
    @character.sheet = @character.sheet.merge("level" => 8)
    @game_table.catalog_entries.create!(kind: "feature", key: "rage", name: "Furie", description: "À la table.")

    class_features = CharacterSheets::Features.new(@character).call.first.features

    assert_equal ["Furie", "Asi", "Attaque supplémentaire"], class_features.map(&:name)
    assert_equal "À la table.", class_features.first.description
  end
end
