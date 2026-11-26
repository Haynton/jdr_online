# A message typed in the chat of the game room. Only someone accepted at the table may write (the same rule as
# GameTableChannel, which sends the feed: an invitation still pending is not enough); anyone else gets a 404. The new
# line goes to the whole table by the channel (ChatMessage); the answer adds it to the page of its author too, so
# that it shows even if their connection is down (Turbo keeps one line per id). Refused, the form comes back with
# its error and the text typed
module GameTables
  class ChatMessagesController < ApplicationController
    def create
      participation = current_user.participations.accepted.find_by!(game_table_id: params[:game_table_id])
      @game_table = participation.game_table
      @chat_message = ChatMessage.post(@game_table, current_user, params.dig(:chat_message, :body))
      @refused_message = @chat_message unless @chat_message.persisted?
      render :create, status: @refused_message ? :unprocessable_content : :ok
    end
  end
end
