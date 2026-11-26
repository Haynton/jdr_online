# The game master gives money to a player from the game room (decision of 26 November: loot, a reward), from the panel
# « Objets »: an amount of a coin the template declares (currency: true, CharacterMoney) goes into the money of the
# complete character of one of its players, never above the most of the coin. Checked by the server: the game master
# of the table (TableOfGameMaster), a character of one of its players, a coin of its sheet; anything else is a 404. The
# gift is written in the feed of the table (ChatMessage), for everyone; back to the room, it is also said in a bubble
module GameTables
  class MoneyGiftsController < ApplicationController
    include TableOfGameMaster

    AMOUNTS = (1..CharacterMoney::MONEY_LIMIT)

    def create
      character = @game_table.characters.pc.complete.find(params.require(:character_id))
      field = character.currency_field(params.require(:coin))
      raise ActiveRecord::RecordNotFound unless field

      amount = params[:amount].to_i.clamp(AMOUNTS.min, AMOUNTS.max)
      give(character, field, amount)
    end

    private

    def give(character, field, amount)
      coin = field["abbreviation"] || field["label"]
      return refuse(character, field, coin) if character.change_money(field, amount) || !character.save

      ChatMessage.record_event(@game_table, :money_given, count: amount, coin: coin, character: character.name)
      redirect_to game_table_path(@game_table),
                  notice: t(".given", count: amount, coin: coin, character: character.name)
    end

    def refuse(character, field, coin)
      redirect_to game_table_path(@game_table),
                  alert: t(".too_much", max: field["max"] || CharacterMoney::MONEY_LIMIT, coin: coin,
                                        character: character.name)
    end
  end
end
