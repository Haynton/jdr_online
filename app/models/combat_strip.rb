# The strip of the fighters of the game room, first version (tried on the local branch style/testing-combat-strip:
# nothing is saved, nothing is shared yet; the dice of the server, the live updates and the state of the tokens come
# with the combat branch). The fighters are the characters of the players and the NPCs and enemies placed on
# the first map of the table that has tokens; their order comes from the last initiative rolled for them in the panel
# « Dés » (DiceRolls::InitiativeRecorder, read in the feed), else from a d20 drawn the same on each load (seeded by
# the character) plus their Dexterity modifier. Each fighter has its own place
# (Anthony's request: one token each); enemies of the same kind (the same name, its number aside: « Guerrier gobelin
# 2 ») roll together in the rules, so they share the initiative of the first of them and follow each other
class CombatStrip
  Fighter = Data.define(:character, :side, :gauge, :armor_class, :attacks, :spell_slots)
  Group = Data.define(:key, :name, :side, :fighters, :initiative)

  NUMBERED_NAME = /\s+\d+\z/

  def initialize(game_room)
    @game_room = game_room
    @game_table = game_room.game_table
  end

  def groups
    @groups ||= begin
      all_fighters = fighters
      initiatives = kind_initiatives(all_fighters)
      all_fighters.map { |fighter| build_group(fighter, initiatives.fetch(kind_key(fighter))) }
                  .sort_by { |group| [-group.initiative, kind_name(group.fighters.first), group.name] }
    end
  end

  # Out of a fight, the strip shows everyone without an order of initiative: the players, then the NPCs and the
  # enemies, each by name
  def resting_groups
    groups.sort_by { |group| [group.side == :player ? 0 : 1, group.name] }
  end

  def conditions
    @game_table.conditions
  end

  RANKS_ID = "combat-initiative-ranks".freeze

  # After a roll of initiative, the strip of the game master gets the new order at once, on their own stream: the rank
  # of each place and the name said to screen readers (« Elowen, initiative 13 »)
  def self.broadcast_initiative_ranks(game_table)
    participation = game_table.participations.find_by(role: :game_master)
    return unless participation

    Turbo::StreamsChannel.broadcast_replace_to(
      game_table, GameTableChannel::GAME_MASTER_AUDIENCE,
      target: RANKS_ID, partial: "game_rooms/combat_initiative_ranks",
      locals: { combat_strip: new(GameRoom.new(participation)) }
    )
  end

  # By the key of each group: its rank in the order of initiative and its initiative
  def initiative_ranks
    groups.each_with_index.to_h { |group, index| [group.key, { rank: index, initiative: group.initiative }] }
  end

  private

  def fighters
    player_fighters + placed_fighters
  end

  def player_fighters
    @game_room.party.reject(&:draft?).map { |character| fighter_of(character, :player) }
  end

  def placed_fighters
    game_map = @game_table.game_maps.find { |candidate| candidate.layout.to_h["tokens"].present? }
    return [] unless game_map

    game_map.placed_tokens.pluck(:character).uniq.map do |character|
      fighter_of(character, character.npc? ? :npc : :enemy)
    end
  end

  def fighter_of(character, side)
    fields = side == :player ? @game_table.character_sheet_fields : @game_table.npc_sheet_fields
    Fighter.new(character:, side:, gauge: gauge_of(character, fields), armor_class: character.sheet.to_h["armor_class"],
                attacks: attacks_of(character, fields),
                spell_slots: (CharacterSheets::SpellSlots.new(character).call if side == :player))
  end

  def gauge_of(character, fields)
    field = fields.find { |candidate| candidate["receives_damage"] }
    value = character.sheet.to_h[field["key"]] if field
    return unless value.is_a?(Hash) && value["max"].to_i.positive?

    { current: value["current"].to_i, max: value["max"].to_i }
  end

  def attacks_of(character, fields)
    field = fields.find { |candidate| candidate["type"] == "attacks" }
    Array(character.sheet.to_h[field["key"]]) if field
  end

  # Enemies of the same kind roll once; anyone else alone
  def kind_key(fighter)
    return "character-#{fighter.character.id}" unless fighter.side == :enemy

    "enemy-#{kind_name(fighter).parameterize}"
  end

  def kind_name(fighter)
    fighter.character.name.to_s.sub(NUMBERED_NAME, "")
  end

  # A kind rolls once: the latest roll of any of its members, else the simulated one of its first
  def kind_initiatives(all_fighters)
    all_fighters.group_by { |fighter| kind_key(fighter) }.transform_values do |members|
      latest_roll_of(members.map { |member| member.character.id }) || initiative_of(members.first.character)
    end
  end

  def latest_roll_of(character_ids)
    initiative_rolls.reverse_each.find { |character_id, _total| character_ids.include?(character_id) }&.last
  end

  def initiative_rolls
    @initiative_rolls ||= ChatMessage.initiative_rolls_of(@game_table)
  end

  def build_group(fighter, initiative)
    Group.new(key: "character-#{fighter.character.id}", name: fighter.character.name.to_s, side: fighter.side,
              fighters: [fighter], initiative:)
  end

  def initiative_of(character)
    d20 = Random.new(character.id).rand(1..20)
    d20 + ModifierRules.modifier(character.sheet.to_h["dexterity"].to_i, "half_above_ten")
  end
end
