# The step "NPCs and enemies" of a table: its list (game_tables/casts/edit), the window of one NPC (its sheet, to see
# and to change: game_tables/npcs) and the window of the bestiary (the creatures of the catalog the table offers, each
# added in one click: game_tables/bestiaries). Like the window of a catalog entry, a link loads its page into the frame
# of its window, which frame_dialog_controller.js opens once it has arrived; opened directly, or without JavaScript,
# each address stays a whole page
module GameTables
  module NpcDialogHelper
    NPC_FRAME = "npc_dialog".freeze
    BESTIARY_FRAME = "bestiary_dialog".freeze

    # Into its window, never prefetched (an answer laid out for the window must not be reused for the whole page)
    def npc_dialog_link_data
      { turbo_frame: NPC_FRAME, turbo_prefetch: false }
    end

    def bestiary_dialog_link_data
      { turbo_frame: BESTIARY_FRAME, turbo_prefetch: false }
    end

    def npc_in_dialog?
      turbo_frame_request_id == NPC_FRAME
    end

    def bestiary_in_dialog?
      turbo_frame_request_id == BESTIARY_FRAME
    end

    # "Enemy · CR 1/4 · AC 15 · HP 10": what it is, then the values the template lists (listed: true), by their
    # abbreviation
    def npc_facts(game_table, npc)
      [t("game_tables.npcs.kinds.#{npc.kind}"), *listed_values(game_table, npc.sheet)].join(" · ")
    end

    # "CR 1/4 · AC 15 · HP 10" for a creature of the bestiary
    def creature_facts(game_table, creature)
      listed_values(game_table, creature.properties).join(" · ")
    end

    # The creatures by the first list the template shows in the list of NPCs (the challenge rating), in the order of
    # its options, then by name; one group without a title for a template that lists none
    def bestiary_groups(game_table, creatures)
      field = listed_fields(game_table).find { |candidate| candidate["options"] }
      sorted = creatures.sort_by { |creature| I18n.transliterate(creature.name).downcase }
      return [[nil, sorted]] unless field

      groups = sorted.group_by { |creature| creature.properties[field["key"]] }
      groups.sort_by { |value, _group| option_rank(field, value) }
            .map { |value, group| ["#{field_short_name(field)} #{value}", group] }
    end

    # The values the window of an NPC shows: every field of the NPC sheet of the table, but those never shown
    def game_table_npc_fields(game_table)
      game_table.npc_sheet_fields.reject { |field| field["internal"] }
    end

    def npc_kind_choices
      Character::GAME_MASTER_KINDS.map { |kind| [t("game_tables.npcs.kinds.#{kind}"), kind] }
    end

    private

    def listed_fields(game_table)
      game_table.npc_sheet_fields.select { |field| field["listed"] }
    end

    def listed_values(game_table, values)
      listed_fields(game_table).filter_map do |field|
        text = FieldTypes.of(field).summary_text(values[field["key"]], field)
        "#{field_short_name(field)} #{text}" if text.present?
      end
    end

    # CR, AC, HP: the abbreviation of a field, or its label
    def field_short_name(field)
      field["abbreviation"] || field["label"]
    end

    # A value out of the options of the list comes last
    def option_rank(field, value)
      field["options"].index(value) || field["options"].size
    end
  end
end
