module CreationStepBehaviors
  # What a step behavior says about itself
  class Base
    KEY = nil

    def key
      self.class::KEY
    end

    # What it adds at the end of the form of its step, and to its block of the summary (paths written in full: a search
    # for a partial finds who draws it; nil for nothing in the block). Both get character:, the form after_sections:
    # (sections shown before it)
    def form_partial
      raise NotImplementedError
    end

    def summary_partial
      raise NotImplementedError
    end

    # Whether its step has something to ask, for the table, the options picked (picked_effects: their effects) and the
    # values of the sheet (its level); a step whose behaviors have nothing is not shown, as a step only_with_effect
    def shown?(_game_table, _picked_effects, _sheet = {})
      true
    end

    # Whether the feats taken (characters.feats) show its step, whatever the options picked (only_with_effect)
    def shown_through_feats?(_feats)
      false
    end

    # On its own step: what it keeps of what was sent (spell_keys: the spells ticked)
    def fill(_character, **); end

    # On the other steps: what it drops that the character no longer gets (a class changed)
    def keep_offered(_character); end
  end
end
