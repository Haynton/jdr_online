# Makes the change of a valid LevelUp, in one transaction: the level written in the sheet, the subclass and its effects
# (CharacterSheets::ChoiceEffectsApplier), the abilities raised, the expertise and the skills of the subclass ticked,
# the options picked in the groups of choices of the class, the hit die rolled or its average kept with the rolls of the
# levels before (nil: the average), the maximum of the hit points worked out again and the current ones raised by the
# same gain, the spells its subclass always prepares copied, and the level given by the game master done, and the spells
# of its feats swapped. Written in the chat for the whole table. Returns the hit points gained
module CharacterSheets
  class LevelUpApplier
    def initialize(level_up)
      @level_up = level_up
      @character = level_up.character
    end

    def call
      previous_max = @character.hit_points&.fetch("max")
      previous_rolls = @character.kept_hit_point_rolls
      @character.transaction do
        write_choices
        gain_hit_die(previous_rolls)
        gained = raise_hit_points(previous_max)
        @character.save!
        record(gained)
        gained
      end
    end

    private

    def write_choices
      new_sheet = @character.sheet.merge(level_values, subclass_values, expertise_values,
                                         (@level_up.chosen_skill_keys + @level_up.feat_skill_keys).index_with(true))
      @character.sheet = ChoiceEffectsApplier.new(fields: @character.sheet_fields, previous_sheet: @character.sheet)
                                             .call(new_sheet)
      @character.class_choices = @level_up.future_character.class_choices
      @character.feats = @level_up.feats_with_swaps + [@level_up.feat_entry].compact
      @character.spellbook = @character.spellbook.to_a + @level_up.spellbook_additions
      @character.sync_feat_spells
      @character.spells = @character.spell_choices.keep_offered(@character.spells.to_a)
      @character.level_up_to = nil
    end

    def level_values
      field = @level_up.level_field
      field ? { field["key"] => @level_up.level } : {}
    end

    def subclass_values
      field = @level_up.subclass_field
      field ? { field["key"] => @level_up.subclass } : {}
    end

    def expertise_values
      @level_up.expertise_keys.index_with { FieldTypes::Bonus::EXPERTISE }
    end

    # A roll adds its result; the average adds a nil to rolls made before, and nothing when no level was rolled
    def gain_hit_die(previous_rolls)
      sides = @level_up.hit_die
      return unless sides

      if @level_up.hit_point_choice == "roll"
        @rolled = rand(1..sides)
        @character.hit_point_method = HitPointMethods::Roll::KEY if players_choose?
        earlier = previous_rolls || Array.new(@level_up.level - 2)
        @character.hit_point_rolls = { "sides" => sides, "results" => earlier + [@rolled] }
      elsif previous_rolls
        @character.hit_point_rolls = { "sides" => sides, "results" => previous_rolls + [nil] }
      end
    end

    def players_choose?
      @character.game_table.players_choose?(CharacterHitPoints::RULE)
    end

    # The maximum worked out again (initial_from of the hit points); the current ones gain as much
    def raise_hit_points(previous_max)
      field = @character.hit_points_field
      maximum = field && @character.computed_sheet_values[:values][field["initial_from"]].to_i
      return 0 unless maximum&.positive? && previous_max

      gained = maximum - previous_max
      current = (@character.hit_points["current"] + gained).clamp(0, maximum)
      @character.sheet = @character.sheet.merge(field["key"] => { "current" => current, "max" => maximum })
      gained
    end

    def record(gained)
      values = { character: @character.name, level: @level_up.level, hit_points: gained }
      return ChatMessage.record_event(@character.game_table, :level_reached, **values) unless @rolled

      ChatMessage.record_event(@character.game_table, :level_reached_rolled, **values, roll: @rolled)
    end
  end
end
