# What changes on a player's character during the game, saved (decision of 26 November): its hit points, its temporary
# hit points and its switches granted in play (the inspiration), changed by the game master from the quick sheet of
# any player, or by a player on their own panel « Ma fiche »; a number the template lets the game master adjust (the
# bonus to the armour class) and a long rest, by the game master only (CharacterVitals); at 0 hit points, a death
# saving throw by either (CharacterDeathSaves), written in the feed with what a hit at 0 does (DeathSaveEvents); a
# short rest by the game master (the resources that come back, CharacterResources).
# Anyone else gets a 404. The new values go to the whole table at once (GameTableChannel): the hit points and the
# temporary ones, the bar, the ring of the portrait, the switches (game_tables/character_vitals/_streams)
module GameTables
  class CharacterVitalsController < ApplicationController
    include SharesCharacterVitals

    before_action { find_character_of_table(params[:id]) }

    def update
      apply_changes
      save_and_share
    end

    def long_rest
      raise ActiveRecord::RecordNotFound unless @participation.game_master?

      @character.take_long_rest
      save_and_share
    end

    # Each resource comes back as its template declares (CharacterResources#take_short_rest)
    def short_rest
      raise ActiveRecord::RecordNotFound unless @participation.game_master?

      @character.take_short_rest
      save_and_share
    end

    # A hit die spent to heal (CharacterHitDice), whenever the player wants: written in the chat for everyone
    def hit_die
      spent = @character.spend_hit_die
      return head(:unprocessable_content) unless spent

      save_and_share do
        ChatMessage.record_event(@game_table, :hit_die_spent, character: @character.name, sides: spent.sides,
                                                              roll: spent.roll, modifier: signed(spent.modifier),
                                                              healed: spent.healed)
      end
    end

    # A death saving throw, rolled by the server, for a character at 0 hit points who is neither stable nor dead
    def death_save
      raise ActiveRecord::RecordNotFound unless @character.dying?

      roll = DiceRolls::Roller.new(count: 1, sides: @character.death_saves_settings["sides"]).call.total
      save_and_share(roll: roll, outcome: @character.take_death_save(roll))
    end

    private

    def apply_changes
      @character.change_hit_points(params[:hit_points_delta].to_i) if params[:hit_points_delta]
      if params[:temporary_hit_points_delta]
        @character.change_temporary_hit_points(params[:temporary_hit_points_delta].to_i)
      end
      @character.switch(params[:switch], params[:switched_on] == "true") if params[:switch]
      adjust_for_game_master if params[:adjust]
    end

    def signed(number)
      number.negative? ? number.to_s : "+#{number}"
    end

    # Only the game master adjusts a number (the bonus to the armour class)
    def adjust_for_game_master
      raise ActiveRecord::RecordNotFound unless @participation.game_master?

      @character.adjust(params[:adjust], params[:adjust_delta].to_i)
    end
  end
end
