class CreateGameTables < ActiveRecord::Migration[8.1]
  def change
    create_table :game_tables do |t|
      t.string :name, null: false, limit: 60
      t.text :description, null: false
      t.string :status, null: false, default: "draft"
      t.integer :creation_step, default: 1
      t.string :invite_token
      t.string :mode
      t.jsonb :template_snapshot, default: {}
      t.jsonb :ai_settings, default: {}
      t.datetime :track_started_at

      t.timestamps
    end
  end
end
