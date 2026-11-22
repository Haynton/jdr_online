# Makes a template of a game master from another one (a predefined template, or one of their own): the first step of
# the template editor (decision: start from a template that works rather than from an empty one). The copy keeps all
# its content (fields, steps, groups of spells, ready-made NPCs and items) and a copy of every line of its catalog
# (decision: the lines are copied, not inherited), so that changing it never changes the original nor the tables
# that use the original. It belongs to the game master, remembers where it comes from (parent) and has no language
# (a template of a game master is written in their own words)
module SheetTemplates
  class Duplicator
    # What the copy takes from the original: its content, never who owns it nor where it comes from
    CONTENT_COLUMNS = %w[
      character_fields npc_fields item_fields spell_fields rest_rules level_thresholds preset_characters preset_items
    ].freeze
    CATALOG_COLUMNS = %w[kind key name description properties].freeze

    def initialize(original:, owner:)
      @original = original
      @owner = owner
    end

    # The copy, saved with its catalog in one transaction
    def call
      SheetTemplate.transaction do
        copy = SheetTemplate.create!(@original.attributes.slice(*CONTENT_COLUMNS)
                                              .merge(name: copy_name, owner: @owner, parent: @original))
        copy_catalog(copy)
        copy
      end
    end

    private

    # "Fantasy héroïque (copie)", cut to the length of a name
    def copy_name
      I18n.t("sheet_templates.duplicates.copy_name", name: @original.name).truncate(SheetTemplate::NAME_MAX_LENGTH)
    end

    # One insert for all the lines: the lines of the original are valid already (CatalogPropertiesValidator), and the
    # copy has the same fields
    def copy_catalog(copy)
      lines = @original.catalog_entries.map do |entry|
        entry.attributes.slice(*CATALOG_COLUMNS).merge("sheet_template_id" => copy.id)
      end
      CatalogEntry.insert_all!(lines) if lines.any?
    end
  end
end
