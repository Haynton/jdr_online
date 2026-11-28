module CreationStepBehaviors
  # The step offers the spells of the class at the level of the character (CharacterSheets::SpellChoices), and copies
  # those ticked into the character; also the spells of the feats of its origin (Magic Initiate, decision of 28
  # November: CharacterFeatSpellPicks), so it shows for a class without spells when such a feat gives some
  class ChoosesSpells < Base
    KEY = "chooses_spells".freeze

    def form_partial
      "game_tables/character_steps/spell_choices"
    end

    def summary_partial
      "character_sheets/summary/spells"
    end

    def fill(character, spell_keys: nil, spellbook_keys: nil, feat_spell_picks: nil, **)
      character.choose_spellbook(spellbook_keys)
      character.choose_spells(spell_keys)
      character.checks_feat_spell_picks = true
      character.choose_feat_spell_picks(feat_spell_picks)
    end

    def shown_through_feats?(feats)
      CharacterFeatSpellPicks.feat_spells_to_pick?(feats)
    end

    # A class changed on another step drops the spells it does not offer, and the spellbook of a class without one
    def keep_offered(character)
      character.spells = character.spell_choices.keep_offered(character.spells)
      character.keep_offered_spellbook
    end
  end
end
