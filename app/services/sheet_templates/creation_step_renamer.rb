# Renames a creation step of a template in the editor, the only change of a step in a template duplicated from a
# working one (decision: its steps and their order stay, its computing rules rely on them; building steps belongs to
# the editor from scratch). The template as a whole is then checked (SheetTemplateValidator: a label filled in, on one
# line, 60 characters at most): false with its errors
module SheetTemplates
  class CreationStepRenamer
    def initialize(sheet_template:, step_key:, label:)
      @sheet_template = sheet_template
      @step_key = step_key
      @label = label.to_s.strip
    end

    # false too for a step the template does not have
    def call
      steps = @sheet_template.character_fields.to_h["creation_steps"].to_a
      return false if steps.none? { |step| step["key"] == @step_key }

      renamed = steps.map { |step| step["key"] == @step_key ? step.merge("label" => @label) : step }
      @sheet_template.character_fields = @sheet_template.character_fields.merge("creation_steps" => renamed)
      @sheet_template.save
    end
  end
end
