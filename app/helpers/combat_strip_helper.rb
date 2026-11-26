# The strip of the fighters of the game room (CombatStrip, game_rooms/_combat_strip): its portraits by side,
# what each person may see (the game master everything; a player never the hit points of an NPC or an enemy, and only
# their own quick sheet)
module CombatStripHelper
  PORTRAIT_SIDE_CLASSES = {
    player: "bg-success-bg text-success-ink", npc: "bg-primary-soft text-primary-soft-ink",
    enemy: "bg-error-bg text-error-ink"
  }.freeze

  def room_combat_strip
    @room_combat_strip ||= CombatStrip.new(@game_room)
  end

  # The number of a numbered creature (« Guerrier gobelin 2 » is 2), 1 for the first of a kind that has others
  def combat_fighter_number(group)
    return unless group.side == :enemy

    number = group.name[/\s(\d+)\z/, 1]
    return number if number

    "1" if room_combat_strip.groups.any? { |other| other.name.start_with?("#{group.name} ") }
  end

  def combat_portrait_classes(group)
    PORTRAIT_SIDE_CLASSES.fetch(group.side)
  end

  def combat_initials(name)
    name.to_s.sub(/\s+\d+\z/, "").split.first(2).map { |word| word[0] }.join.upcase
  end

  def combat_gauge_shown?(game_room, group)
    game_room.game_master? || group.side == :player
  end

  def combat_sheet_openable?(game_room, group)
    return true if game_room.game_master?

    group.fighters.any? { |fighter| fighter.character.participation_id == game_room.participation.id }
  end

  # What is left of the gauges of a group, from 0 to 100: the ring around its portrait
  def combat_group_percent(group)
    gauges = group.fighters.filter_map(&:gauge)
    return if gauges.empty?

    (100.0 * gauges.sum { |gauge| gauge[:current] } / gauges.sum { |gauge| gauge[:max] }).round
  end

  # The choices shown under the name of a player (Anthony's request: the class and the species only), precise fields
  SUBTITLE_FIELD_KEYS = %w[class species].freeze

  # Under the name in the quick sheet: the class and the species of a player's character (« Druide · Elfe »), « PNJ »
  # or « Ennemi » for a creature
  def combat_fighter_subtitle(fighter)
    return t("game_tables.npcs.kinds.#{fighter.character.kind}") unless fighter.side == :player

    character = fighter.character
    character.sheet_fields.select { |field| SUBTITLE_FIELD_KEYS.include?(field["key"]) }.filter_map do |field|
      value = character.sheet[field["key"]]
      FieldTypes.of(field).summary_text(value, field) if value.present?
    end.join(" · ")
  end

  def combat_gauge_percent(gauge)
    (100.0 * gauge[:current] / gauge[:max]).round
  end

  def combat_attack_text(attack)
    to_hit = attack["to_hit"].to_i
    ["#{attack['name']} #{to_hit.negative? ? to_hit : "+#{to_hit}"}", attack["damage"], attack["range"]].compact_blank
  end

  def combat_full_sheet_link(game_room, fighter)
    character = fighter.character
    if fighter.side == :player
      link_to t("game_rooms.combat_strip.full_sheet"), game_table_character_sheet_path(game_room.game_table, character),
              class: "font-medium text-link hover:underline", data: character_sheet_dialog_link_data
    else
      link_to t("game_rooms.combat_strip.full_sheet"), edit_game_table_npc_path(game_room.game_table, character),
              class: "font-medium text-link hover:underline", data: npc_dialog_link_data
    end
  end
end
