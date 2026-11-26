# A player adds coins to the money of their character or takes some out (decision of 26 November: loot shared, a sale,
# a purchase), from the panel « Inventaire » of the game room: a coin its template declares (currency: true,
# CharacterMoney), an amount of 1 or more, never below 0 nor above the most of the coin. Saved: only a player accepted
# at the table, for their own complete character; anyone else gets a 404. The answer redraws the panel in place, the
# error under the form when the amount is refused
module GameTables
  class PursesController < ApplicationController
    def update
      participation = current_user.participations.accepted.player.find_by!(game_table_id: params[:game_table_id])
      character = participation.character
      field = character&.complete? && character.currency_field(params[:coin])
      raise ActiveRecord::RecordNotFound unless field

      error = change_money(character, field)
      locals = { game_room: GameRoom.new(participation), purse_error: error, purse_coin: field["key"] }
      render turbo_stream: turbo_stream.replace("game-room-inventory", partial: "game_rooms/panels/inventory",
                                                                       locals: locals),
             status: error ? :unprocessable_content : :ok
    end

    private

    # The error to show, nil once the coins are added or taken out
    def change_money(character, field)
      amount = Integer(params[:amount].to_s, exception: false)
      return t(".invalid_amount") unless amount&.positive?

      error = character.change_money(field, params[:direction] == "remove" ? -amount : amount)
      return money_error(error, character, field) if error

      t(".not_saved") unless character.save
    end

    def money_error(error, character, field)
      t(".#{error}", count: character.coins_of(field), max: field["max"] || CharacterMoney::MONEY_LIMIT,
                     coin: field["abbreviation"] || field["label"])
    end
  end
end
