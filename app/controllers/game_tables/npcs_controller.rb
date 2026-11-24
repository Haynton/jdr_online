# One NPC or enemy of a table (a character of kind npc or monster), in a window over the step "NPCs and enemies"
# (GameTables::NpcDialogHelper): its name, what it is (an NPC or an enemy), the notes of the game master, then every
# value of the NPC sheet the template declares, checked by their types (CharacterSheetValidator). Saved in the window,
# the list behind is refreshed and the window closes; refused, the errors stay in it.
# From the bestiary (catalog_key), a creature is copied in one click (Catalogs::CreatureCopier): the list behind is
# replaced and the bestiary stays open, to add several. The switch "Shown to the players" of a line saves only it
module GameTables
  class NpcsController < ApplicationController
    include TableOfGameMaster
    include NpcDialogHelper
    include VariesOnTurboFrame

    before_action :set_npc, only: %i[edit update destroy]

    def new
      @npc = new_npc
    end

    def create
      return add_from_bestiary if params[:catalog_key].present?

      @npc = new_npc
      save_npc(:new)
    end

    def edit
    end

    def update
      save_npc(:edit)
    end

    def destroy
      @npc.destroy!
      show_list
    end

    private

    # Hidden from the players until the game master shows it (the column says shown, as for a player character)
    def new_npc
      @game_table.characters.build(kind: :npc, visible_to_players: false)
    end

    # Only the NPCs and enemies of the table: never a player character
    def set_npc
      @npc = @game_table.npcs.find(params[:id])
    end

    def save_npc(form_action)
      @npc.assign_attributes(npc_attributes)
      return show_list if @npc.save

      render form_action, status: :unprocessable_content
    end

    # What was sent, only: the switch of a line sends its visibility alone. The values of the sheet are converted by the
    # type of their field (CharacterSheets::Builder), as on a player character sheet
    def npc_attributes
      attributes = npc_params.slice(:name, :gm_notes, :visible_to_players).to_h
      attributes[:kind] = npc_params[:kind] if Character::GAME_MASTER_KINDS.include?(npc_params[:kind])
      attributes[:sheet] = submitted_sheet if npc_params.key?(:sheet)
      attributes
    end

    def submitted_sheet
      CharacterSheets::Builder.new(fields: @game_table.npc_sheet_fields, submitted_values: npc_params[:sheet]).call
    end

    def npc_params
      params.fetch(:npc, {}).permit(:name, :kind, :gm_notes, :visible_to_players, sheet: {})
    end

    # The bestiary stays open: the list behind is replaced, and the window says what was added (for screen readers)
    def add_from_bestiary
      npc = Catalogs::CreatureCopier.new(@game_table).call(params[:catalog_key])
      notice = t(".added", name: npc.name)
      return redirect_to(edit_game_table_cast_path(@game_table), notice: notice) unless bestiary_in_dialog?

      render turbo_stream: [
        turbo_stream.replace("cast-list", partial: "game_tables/casts/list", locals: { npcs: @game_table.npcs }),
        turbo_stream.update("bestiary-status", notice)
      ]
    end

    # In the window: the list behind is drawn again, where it was. Opened directly, or by a switch: back to the list
    def show_list
      return render(turbo_stream: turbo_stream.refresh(request_id: nil)) if npc_in_dialog?

      redirect_to edit_game_table_cast_path(@game_table)
    end
  end
end
