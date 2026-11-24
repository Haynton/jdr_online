module MapTemplates
  # Copies a map of « Mes cartes » into a table (step Maps of its creation): its name, the size of its grid and its
  # whole drawing (floors, walls and doors, objects, how it is made and how its picture sits), so that the board of
  # the table reads the properties of each cell (Anthony: the tokens will move on them). Its picture is copied too, a
  # file of its own: the table keeps its copy whole when the map of « Mes cartes » changes or is deleted
  class TableCopier
    def initialize(map_template, game_table)
      @map_template = map_template
      @game_table = game_table
    end

    def call
      game_map = @game_table.game_maps.build(map_template: @map_template, name: @map_template.name,
                                             columns: @map_template.columns, rows: @map_template.rows,
                                             layout: @map_template.layout.deep_dup)
      copy_picture(game_map) if @map_template.picture.attached?
      game_map.save!
      game_map
    end

    private

    # Read whole before the copy is saved (10 MB at most): a file opened in a block would be closed by then
    def copy_picture(game_map)
      blob = @map_template.picture.blob
      game_map.image.attach(io: StringIO.new(blob.download), filename: blob.filename.to_s,
                            content_type: blob.content_type)
    end
  end
end
