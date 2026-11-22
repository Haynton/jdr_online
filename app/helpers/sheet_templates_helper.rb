# The pages of the templates of a game master ("My templates", the page of one of them): their cards and what a
# template holds, read from its JSON and its catalog
module SheetTemplatesHelper
  # A card of the list, a link to the page of the template (its border gold on hover, like a card of "My tables")
  TEMPLATE_CARD_CLASSES = "flex h-full flex-col gap-1 rounded-xl border border-line bg-surface px-5 py-4".freeze
  TEMPLATE_LINK_CARD_CLASSES = "#{TEMPLATE_CARD_CLASSES} transition-colors hover:border-brass".freeze

  # "48 champs et 7 étapes de création": the character sheet of the template
  def sheet_template_contents(sheet_template)
    character_fields = sheet_template.character_fields.to_h
    [t("sheet_templates.contents.fields", count: character_fields["fields"].to_a.size),
     sheet_template_steps(character_fields["creation_steps"].to_a.size)].to_sentence
  end

  # No steps: the whole sheet on one page. Said apart, since French counts 0 as one ("0 étape")
  def sheet_template_steps(count)
    return t("sheet_templates.contents.single_page") if count.zero?

    t("sheet_templates.contents.steps", count: count)
  end

  # "141 sorts et 95 objets", in the order of the kinds (CatalogEntry::KINDS), or that the catalog is empty
  def sheet_template_catalog(sheet_template)
    counts = sheet_template.catalog_entries.group(:kind).count
    return t("sheet_templates.contents.empty_catalog") if counts.empty?

    CatalogEntry::KINDS.filter_map do |kind|
      t("sheet_templates.contents.catalog.#{kind}", count: counts[kind]) if counts[kind]
    end.to_sentence
  end

  # "D'après « Fantasy héroïque »", nil for a template made from nothing (or whose original was deleted)
  def sheet_template_origin(sheet_template)
    t("sheet_templates.contents.from", name: sheet_template.parent.name) if sheet_template.parent
  end
end
