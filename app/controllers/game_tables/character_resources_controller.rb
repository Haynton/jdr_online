# A resource of a player's character spent or given back in the game room (decision of 26 November: a rage, a channel
# divinity, points of a pool), by its player or the game master (SharesCharacterVitals: a 404 for anyone else): one
# use, or an amount for a pool (the lay on hands), never more than is left nor below nothing spent. A use spent is
# written in the feed of the table, for everyone; given back is a correction, not written. The new values go to the
# whole table at once
module GameTables
  class CharacterResourcesController < ApplicationController
    include SharesCharacterVitals

    AMOUNTS = (1..999)

    before_action { find_character_of_table(params[:character_vital_id]) }

    def update
      resource = @character.resource(params[:key])
      raise ActiveRecord::RecordNotFound unless resource

      amount = resource.pool ? params[:amount].to_i.clamp(AMOUNTS.min, AMOUNTS.max) : 1
      spent = params[:resource_change] == "spend"
      return head(:unprocessable_content) if @character.change_resource(resource, spent ? amount : -amount)

      save_and_share { record_use(resource.key, amount) if spent }
    end

    private

    def record_use(key, amount)
      resource = @character.resource(key)
      ChatMessage.record_event(@game_table, resource.pool ? :resource_pool_used : :resource_used,
                               character: @character.name, resource: resource.label, count: amount,
                               left: resource.left, total: resource.total)
    end
  end
end
