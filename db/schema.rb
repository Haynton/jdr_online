# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_21_103145) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "game_tables", force: :cascade do |t|
    t.string "name", limit: 60, null: false
    t.text "description"
    t.string "status", default: "draft", null: false
    t.integer "creation_step", default: 1
    t.string "invite_token"
    t.string "mode"
    t.jsonb "template_snapshot", default: {}
    t.jsonb "ai_settings", default: {}
    t.datetime "track_started_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "cover_image", default: "sentinelle", null: false
    t.bigint "sheet_template_id"
    t.index ["sheet_template_id"], name: "index_game_tables_on_sheet_template_id"
  end

  create_table "participations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "game_table_id", null: false
    t.string "role", default: "player", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_table_id"], name: "index_participations_on_game_table_id"
    t.index ["game_table_id"], name: "index_participations_one_game_master_per_table", unique: true, where: "((role)::text = 'game_master'::text)"
    t.index ["user_id", "game_table_id"], name: "index_participations_on_user_and_game_table", unique: true
    t.index ["user_id"], name: "index_participations_on_user_id"
    t.check_constraint "role::text = ANY (ARRAY['game_master'::character varying, 'player'::character varying]::text[])", name: "participations_role_check"
  end

  create_table "sheet_templates", force: :cascade do |t|
    t.string "name", limit: 60, null: false
    t.bigint "owner_id"
    t.bigint "parent_id"
    t.jsonb "character_fields", default: {}, null: false
    t.jsonb "npc_fields", default: {}, null: false
    t.jsonb "item_fields", default: {}, null: false
    t.jsonb "rest_rules", default: [], null: false
    t.jsonb "level_thresholds", default: [], null: false
    t.jsonb "preset_characters", default: [], null: false
    t.jsonb "preset_items", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "locale"
    t.index ["owner_id"], name: "index_sheet_templates_on_owner_id"
    t.index ["parent_id"], name: "index_sheet_templates_on_parent_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "locale"
    t.string "username", null: false
    t.index "lower((username)::text)", name: "index_users_on_lower_username", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "game_tables", "sheet_templates", on_delete: :nullify
  add_foreign_key "participations", "game_tables"
  add_foreign_key "participations", "users"
  add_foreign_key "sheet_templates", "sheet_templates", column: "parent_id"
  add_foreign_key "sheet_templates", "users", column: "owner_id"
end
