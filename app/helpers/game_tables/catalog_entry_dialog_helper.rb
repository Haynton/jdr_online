# The window of a spell or an item of the catalog of a table, over the step "Spells and items", like the window of a
# field in the template editor: a line of the list loads its form into the frame of the window
# (game_tables/catalogs/_dialog), which frame_dialog_controller.js opens once it has arrived. Opened directly, or
# without JavaScript, the address of the form stays a whole page
module GameTables
  module CatalogEntryDialogHelper
    FRAME = "catalog_entry_dialog".freeze
    # Where a value sits in the window, a grid of 6 columns once it is 576 px wide (decision: the layout of a sheet,
    # made for a narrow column, left half the window empty): lists and short texts three per line, switches two per
    # line, long texts and check boxes across (their options on 4 columns), a short group of boxes (V, S, M) on two
    # columns, leaving room beside it
    CELL_CLASSES = {
      lists: "@xl:col-span-2", boxes: "@xl:col-span-2", switches: "@xl:col-span-3", texts: "@xl:col-span-6"
    }.freeze
    SHORT_PICKS_CELL_CLASSES = "@xl:col-span-2".freeze
    PICKS_CELL_CLASSES = "@xl:col-span-6".freeze
    SHORT_PICKS_COUNT = 4

    # Into the window, never prefetched (an answer laid out for the window must not be reused for the whole page)
    def catalog_entry_dialog_link_data
      { turbo_frame: FRAME, turbo_prefetch: false }
    end

    def catalog_entry_in_dialog?
      turbo_frame_request_id == FRAME
    end

    # The values the window shows: every field the template of the table declares for the kind (the same fields that
    # check the entry once saved, CatalogEntry.declared_fields), but those never shown (internal)
    def catalog_entry_shown_fields(game_table, kind)
      column = CatalogEntry::PROPERTY_FIELDS_COLUMNS[kind]
      fields = column ? CatalogEntry.declared_fields(game_table, column).to_a : []
      fields.reject { |field| field["internal"] }
    end

    def catalog_entry_cell_classes(field)
      group = sheet_flow_group(field)
      return CELL_CLASSES.fetch(group, PICKS_CELL_CLASSES) unless group == :picks

      field["options"].to_a.size <= SHORT_PICKS_COUNT ? SHORT_PICKS_CELL_CLASSES : PICKS_CELL_CLASSES
    end

    # The fields by the section the template gives them ("Level and school", "Casting"...), in the order they first
    # come: [section, fields]; a field without a section in a group without a title. In a section, the fields by kind
    # of input (the lists and short texts, the boxes, the check boxes, the long texts, then the switches together), in
    # the order of the template within each kind: the switches side by side, wherever the template puts them
    def catalog_entry_sections(fields)
      fields.group_by { |field| field["section"] }.map do |section, section_fields|
        [section, section_fields.sort_by.with_index { |field, index| [catalog_group_rank(field), index] }]
      end
    end

    def catalog_group_rank(field)
      groups = CharacterSheets::LayoutHelper::FLOW_GROUPS
      groups.index(sheet_flow_group(field)) || groups.size
    end

    # The table's own entry changes the original of its template (same key): "Changed"; one of its own: "Added"
    def catalog_entry_origin(game_table, entry)
      return if entry.new_record? || entry.game_table_id.nil?

      template_has_key = CatalogEntry.exists?(sheet_template_id: game_table.sheet_template_id, kind: entry.kind,
                                              key: entry.key)
      template_has_key ? :changed : :added
    end
  end
end
