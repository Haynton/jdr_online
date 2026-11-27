# The live streams of a game table (the game room: dice, chat, tokens), heard only by the people at the table: its
# game master and its accepted players, checked again at every subscription. A second stream, for the game master
# only, carries what the players must not see (hidden NPCs, secret rolls). A third one, for one participation only,
# carries what a single person may see (the token of their character, hidden from the others). Put in a page by
# game_table_stream_from(game_table) (GameTableStreamsHelper), sent to with the usual Turbo broadcasts:
# Turbo::StreamsChannel.broadcast_append_to(game_table, ...), for the game master
# (game_table, GameTableChannel::GAME_MASTER_AUDIENCE, ...), for one person (game_table, participation, ...).
#
# Turbo's own channel only checks the signature of a stream name, never who listens, and a signed name never expires:
# a player removed from the table could keep listening with the name of their old page. So the names of this channel
# are signed for it alone (SIGNATURE_PURPOSE), which Turbo's channel refuses. Never write turbo_stream_from game_table
# in a page: it would give a name that Turbo's channel accepts
class GameTableChannel < Turbo::StreamsChannel
  SIGNATURE_PURPOSE = :game_table_stream
  GAME_MASTER_AUDIENCE = "game_master".freeze

  def self.signed_stream_name_for(game_table, game_master_only: false, participation: nil)
    streamables = streamables_for(game_table, game_master_only:, participation:)
    Turbo.signed_stream_verifier.generate(stream_name_from(streamables), purpose: SIGNATURE_PURPOSE)
  end

  def self.streamables_for(game_table, game_master_only:, participation:)
    return [game_table, participation] if participation

    game_master_only ? [game_table, GAME_MASTER_AUDIENCE] : [game_table]
  end

  def subscribed
    stream_name = Turbo.signed_stream_verifier.verified(params[:signed_stream_name], purpose: SIGNATURE_PURPOSE)
    return reject unless stream_name && may_listen_to?(stream_name)

    stream_from stream_name
  end

  private

  # The stream name is the table (its GlobalID), then the audience: the game master, or one participation (its GlobalID)
  def may_listen_to?(stream_name)
    game_table_id, audience = stream_name.split(":", 2)
    participation = participation_at(GlobalID::Locator.locate(game_table_id, only: GameTable))
    return false unless participation

    audience.nil? || audience == participation.to_gid_param ||
      (audience == GAME_MASTER_AUDIENCE && participation.game_master?)
  end

  # Accepted only: an invitation not answered yet does not let one in
  def participation_at(game_table)
    return unless game_table

    current_user.participations.accepted.find_by(game_table: game_table)
  end
end
