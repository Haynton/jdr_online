# The creation path of a template in the editor (sheet_templates/fields/index): its steps in their order (decision: a
# template duplicated from a working one keeps its steps and their order, which its computing rules rely on), each
# with its sections and their fields, so that the game master sees where each field is asked and what to change
module SheetTemplates
  module CreationPathHelper
    # The title and the hint of a block that is not a declared step
    PATH_BLOCK_TEXTS = {
      single_page: { title: "sheet_templates.fields.path_step.single_page",
                     hint: "sheet_templates.fields.path_step.single_page_hint" },
      left_out: { title: "sheet_templates.fields.path_step.left_out",
                  hint: "sheet_templates.fields.path_step.left_out_hint" }
    }.freeze

    # Each step with its sections and their fields, in the order of the template: [{ kind: :step, step:, sections:
    # [[name, fields]] }]. A template without steps, one block for its single page (kind: :single_page). Sections no
    # step asks (only filled in the game) come last (kind: :left_out)
    def creation_path(sheet_template)
      fields_by_section = sheet_template.character_fields.to_h["fields"].to_a.group_by { |field| field["section"] }
      steps = sheet_template.character_fields.to_h["creation_steps"].to_a
      return [{ kind: :single_page, sections: fields_by_section.to_a }] if steps.empty?

      blocks = steps.map do |step|
        { kind: :step, step: step, sections: step["sections"].to_a.map { |name| [name, fields_by_section[name].to_a] } }
      end
      left_out = fields_by_section.except(*steps.flat_map { |step| step["sections"].to_a })
      left_out.any? ? blocks + [{ kind: :left_out, sections: left_out.to_a }] : blocks
    end

    # When a step shows, said in words: only on the summary, or only with an option that has an effect
    def creation_step_note(step)
      return t("sheet_templates.fields.index.summary_only") if step["summary_only"]

      effect = step["only_with_effect"]
      return unless effect

      t("sheet_templates.fields.index.only_with_effect", effect: t("sheet_templates.creation_path.effects.#{effect}"))
    end

    # A field the player does not type: worked out (its type stores nothing), given by the table, used in the game
    # only, or internal (worked out to fill another field)
    def field_path_note(field)
      note = field_path_note_key(field)
      t("sheet_templates.creation_path.notes.#{note}") if note
    end

    private

    def field_path_note_key(field)
      return :internal if field["internal"]
      return :computed unless FieldTypes.of(field).stored?
      return :from_table if field["from_table"]

      :in_game if field["at_creation"] == false
    end
  end
end
