# The live streams of a game table in a page, through GameTableChannel (never turbo_stream_from, see the channel)
module GameTableStreamsHelper
  def game_table_stream_from(game_table, game_master_only: false, participation: nil)
    signed_stream_name = GameTableChannel.signed_stream_name_for(game_table, game_master_only:, participation:)
    tag.turbo_cable_stream_source(channel: GameTableChannel.name, 'signed-stream-name': signed_stream_name)
  end
end
