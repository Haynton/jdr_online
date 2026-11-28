# The budget of a combat encounter for a table (decision of 27 November, SRD 5.2.1), read in what its template declares
# (TemplateCopy#encounters): for each difficulty, the sum over the finished characters of the players of what their
# level gives; and the experience points of each creature the game master may put in it, its NPCs and enemies first,
# then the bestiary of the table, by their challenge rating. Nothing is saved: the panel « Rencontre » adds them up
class EncounterBudget
  Difficulty = Data.define(:key, :label, :help, :budget)
  Creature = Data.define(:key, :name, :rating, :xp)

  def initialize(game_table)
    @game_table = game_table
    @declared = game_table.encounters
  end

  def declared?
    @declared.present?
  end

  def label
    @declared["label"]
  end

  def help
    @declared["help"]
  end

  # The levels of the characters of the players, finished, in order
  def party_levels
    @party_levels ||= @game_table.characters.where(kind: :pc, status: :complete).map(&:current_level).sort
  end

  def difficulties
    @declared["difficulties"].each_with_index.map do |difficulty, index|
      Difficulty.new(key: difficulty["key"], label: difficulty["label"], help: difficulty["help"],
                     budget: party_levels.sum { |level| budget_row(level)[index].to_i })
    end
  end

  def creatures
    own = @game_table.npcs.map { |npc| creature("npc-#{npc.id}", npc.name, npc.sheet) }
    bestiary = Catalogs::TableCatalog.new(@game_table).entries("monster").map do |entry|
      creature(entry.key, entry.name, entry.properties)
    end
    own + bestiary.sort_by { |candidate| [candidate.xp, I18n.transliterate(candidate.name).downcase] }
  end

  private

  def budget_row(level)
    rows = @declared["budget_by_level"]
    rows[level.clamp(1, rows.size) - 1]
  end

  def creature(key, name, values)
    rating = values.to_h[@declared["rating_from"]].to_s
    Creature.new(key: key, name: name, rating: rating, xp: @declared["xp_by_rating"].to_h[rating].to_i)
  end
end
