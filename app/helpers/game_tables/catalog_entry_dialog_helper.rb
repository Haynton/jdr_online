# The window of a spell or an item of the catalog of a table, over the step "Spells and items", like the window of a
# field in the template editor: a line of the list loads its form into the frame of the window
# (game_tables/catalogs/_dialog), which frame_dialog_controller.js opens once it has arrived. Opened directly, or
# without JavaScript, the address of the form stays a whole page
module GameTables
  module CatalogEntryDialogHelper
    FRAME = "catalog_entry_dialog".freeze

    # Into the window, never prefetched (an answer laid out for the window must not be reused for the whole page)
    def catalog_entry_dialog_link_data
      { turbo_frame: FRAME, turbo_prefetch: false }
    end

    def catalog_entry_in_dialog?
      turbo_frame_request_id == FRAME
    end

    # The values the window shows: every field the template declares for the kind, but those never shown (internal)
    def catalog_entry_shown_fields(entry)
      entry.property_fields.to_a.reject { |field| field["internal"] }
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
