# What the controllers of the values a player's character changes in the game room share (CharacterVitalsController,
# CharacterResourcesController): who may change them (the game master for any player of the table, a player for
# their own, a 404 for anyone else), and once saved, the death saving throws written in the feed and the new values
# sent to the whole table at once (game_tables/character_vitals/_streams)
module SharesCharacterVitals
  extend ActiveSupport::Concern

  private

  def find_character_of_table(character_id)
    @participation = current_user.participations.accepted.find_by!(game_table_id: params[:game_table_id])
    @game_table = @participation.game_table
    @character = @game_table.characters.pc.find(character_id)
    own_character = @character.participation_id == @participation.id
    raise ActiveRecord::RecordNotFound unless @participation.game_master? || own_character

    @death_save_events = CharacterSheets::DeathSaveEvents.new(@character)
  end

  # death_save: the roll and the outcome of a death saving throw, written in the feed with what it changed
  def save_and_share(**death_save)
    return head(:unprocessable_content) unless @character.save

    @death_save_events.record(**death_save)
    yield if block_given?
    streams = render_to_string(partial: "game_tables/character_vitals/streams", formats: [:turbo_stream],
                               locals: { character: @character })
    Turbo::StreamsChannel.broadcast_stream_to(@game_table, content: streams)
    render turbo_stream: streams
  end
end
