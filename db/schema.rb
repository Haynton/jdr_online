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

ActiveRecord::Schema[8.1].define(version: 2026_11_26_233000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "catalog_entries", force: :cascade do |t|
    t.bigint "sheet_template_id"
    t.string "kind", null: false
    t.string "key", null: false
    t.string "name", limit: 60, null: false
    t.text "description"
    t.jsonb "properties", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "game_table_id"
    t.index ["game_table_id", "kind", "key"], name: "index_catalog_entries_on_game_table_id_and_kind_and_key", unique: true, where: "(game_table_id IS NOT NULL)"
    t.index ["properties"], name: "index_catalog_entries_on_properties", using: :gin
    t.index ["sheet_template_id", "kind", "key"], name: "index_catalog_entries_on_sheet_template_id_and_kind_and_key", unique: true
    t.index ["sheet_template_id", "kind", "name"], name: "index_catalog_entries_on_sheet_template_id_and_kind_and_name"
    t.check_constraint "(sheet_template_id IS NULL) <> (game_table_id IS NULL)", name: "catalog_entries_one_owner_check"
    t.check_constraint "kind::text = ANY (ARRAY['spell'::character varying, 'item'::character varying, 'npc'::character varying, 'monster'::character varying, 'feature'::character varying]::text[])", name: "catalog_entries_kind_check"
  end

  create_table "characters", force: :cascade do |t|
    t.bigint "game_table_id", null: false
    t.string "kind", default: "pc", null: false
    t.bigint "participation_id"
    t.string "name", limit: 60
    t.jsonb "sheet", default: {}, null: false
    t.boolean "visible_to_players", default: true, null: false
    t.text "gm_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "complete", null: false
    t.string "creation_step"
    t.jsonb "spells", default: [], null: false
    t.string "ability_method"
    t.string "hit_point_method"
    t.jsonb "hit_point_rolls", default: {}, null: false
    t.bigint "owner_character_id"
    t.jsonb "resources_used", default: {}, null: false
    t.jsonb "spell_slots_used", default: {}, null: false
    t.integer "hit_dice_used", default: 0, null: false
    t.string "fighting_style"
    t.jsonb "weapon_masteries", default: [], null: false
    t.integer "level_up_to"
    t.index ["game_table_id", "kind"], name: "index_characters_on_game_table_id_and_kind"
    t.index ["game_table_id"], name: "index_characters_on_game_table_id"
    t.index ["owner_character_id"], name: "index_characters_on_owner_character_id"
    t.index ["participation_id"], name: "index_characters_one_pc_per_participation", unique: true, where: "((kind)::text = 'pc'::text)"
    t.check_constraint "kind::text = ANY (ARRAY['pc'::character varying, 'npc'::character varying, 'monster'::character varying, 'companion'::character varying]::text[])", name: "characters_kind_check"
    t.check_constraint "level_up_to >= 2 AND level_up_to <= 20", name: "characters_level_up_to_check"
    t.check_constraint "owner_character_id IS NULL OR kind::text = 'companion'::text", name: "characters_owner_only_for_companion_check"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'complete'::character varying]::text[])", name: "characters_status_check"
  end

  create_table "chat_messages", force: :cascade do |t|
    t.bigint "game_table_id", null: false
    t.bigint "user_id"
    t.string "author_name", limit: 60
    t.string "kind", default: "message", null: false
    t.text "body"
    t.string "event_key"
    t.jsonb "event_params", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "game_master_only", default: false, null: false
    t.index ["game_table_id", "created_at"], name: "index_chat_messages_on_game_table_id_and_created_at"
    t.index ["user_id"], name: "index_chat_messages_on_user_id"
    t.check_constraint "kind::text <> 'event'::text OR event_key IS NOT NULL", name: "chat_messages_event_key_check"
    t.check_constraint "kind::text <> 'message'::text OR body IS NOT NULL", name: "chat_messages_message_body_check"
    t.check_constraint "kind::text = ANY (ARRAY['message'::character varying, 'event'::character varying]::text[])", name: "chat_messages_kind_check"
  end

  create_table "friendships", force: :cascade do |t|
    t.bigint "requester_id", null: false
    t.bigint "addressee_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "LEAST(requester_id, addressee_id), GREATEST(requester_id, addressee_id)", name: "index_friendships_one_per_pair", unique: true
    t.index ["addressee_id"], name: "index_friendships_on_addressee_id"
    t.index ["requester_id"], name: "index_friendships_on_requester_id"
    t.check_constraint "requester_id <> addressee_id", name: "friendships_not_oneself_check"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'accepted'::character varying]::text[])", name: "friendships_status_check"
  end

  create_table "game_maps", force: :cascade do |t|
    t.bigint "game_table_id", null: false
    t.string "name", limit: 60, null: false
    t.integer "grid_cell_size", default: 50, null: false
    t.boolean "grid_visible", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "map_template_id"
    t.integer "columns"
    t.integer "rows"
    t.jsonb "layout"
    t.index ["game_table_id"], name: "index_game_maps_on_game_table_id"
    t.index ["map_template_id"], name: "index_game_maps_on_map_template_id"
    t.check_constraint "columns IS NULL OR columns >= 10 AND columns <= 60", name: "game_maps_columns_check"
    t.check_constraint "grid_cell_size >= 10 AND grid_cell_size <= 500", name: "game_maps_grid_cell_size_check"
    t.check_constraint "rows IS NULL OR rows >= 10 AND rows <= 60", name: "game_maps_rows_check"
  end

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
    t.integer "starting_level", default: 1, null: false
    t.boolean "players_choose_level", default: false, null: false
    t.jsonb "disabled_catalog_keys", default: {}, null: false
    t.jsonb "rules", default: {}, null: false
    t.boolean "limit_skill_choices", default: true, null: false
    t.bigint "board_game_map_id"
    t.index ["board_game_map_id"], name: "index_game_tables_on_board_game_map_id"
    t.index ["invite_token"], name: "index_game_tables_on_invite_token", unique: true
    t.index ["sheet_template_id"], name: "index_game_tables_on_sheet_template_id"
    t.check_constraint "starting_level >= 1 AND starting_level <= 20", name: "game_tables_starting_level_check"
  end

  create_table "inventory_items", force: :cascade do |t|
    t.bigint "character_id", null: false
    t.string "key"
    t.string "name", limit: 60, null: false
    t.text "description"
    t.jsonb "properties", default: {}, null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "equipped", default: false, null: false
    t.index ["character_id"], name: "index_inventory_items_on_character_id"
    t.check_constraint "quantity > 0", name: "inventory_items_quantity_positive"
  end

  create_table "map_templates", force: :cascade do |t|
    t.bigint "owner_id", null: false
    t.string "name", limit: 60, null: false
    t.integer "columns", default: 28, null: false
    t.integer "rows", default: 21, null: false
    t.jsonb "layout", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_map_templates_on_owner_id"
    t.check_constraint "columns >= 10 AND columns <= 60", name: "map_templates_columns_check"
    t.check_constraint "rows >= 10 AND rows <= 60", name: "map_templates_rows_check"
  end

  create_table "participations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "game_table_id", null: false
    t.string "role", default: "player", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "accepted", null: false
    t.index ["game_table_id"], name: "index_participations_on_game_table_id"
    t.index ["game_table_id"], name: "index_participations_one_game_master_per_table", unique: true, where: "((role)::text = 'game_master'::text)"
    t.index ["user_id", "game_table_id"], name: "index_participations_on_user_and_game_table", unique: true
    t.index ["user_id"], name: "index_participations_on_user_id"
    t.check_constraint "role::text = ANY (ARRAY['game_master'::character varying, 'player'::character varying]::text[])", name: "participations_role_check"
    t.check_constraint "status::text = ANY (ARRAY['accepted'::character varying, 'pending'::character varying]::text[])", name: "participations_status_check"
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
    t.jsonb "preset_items", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "locale"
    t.jsonb "spell_fields", default: {}, null: false
    t.text "description"
    t.string "icon", default: "scroll_text", null: false
    t.string "banner_color", default: "gold", null: false
    t.index ["owner_id"], name: "index_sheet_templates_on_owner_id"
    t.index ["parent_id"], name: "index_sheet_templates_on_parent_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.binary "payload", null: false
    t.datetime "created_at", null: false
    t.bigint "channel_hash", null: false
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_batch_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "batch_id", null: false
    t.datetime "created_at", null: false
    t.index ["batch_id"], name: "index_solid_queue_batch_executions_on_batch_id"
    t.index ["job_id"], name: "index_solid_queue_batch_executions_on_job_id", unique: true
  end

  create_table "solid_queue_batches", force: :cascade do |t|
    t.string "active_job_batch_id"
    t.string "description"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_failure"
    t.text "metadata"
    t.integer "total_jobs", default: 0, null: false
    t.integer "completed_jobs", default: 0, null: false
    t.integer "failed_jobs", default: 0, null: false
    t.datetime "enqueued_at"
    t.datetime "finished_at"
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_batch_id"], name: "index_solid_queue_batches_on_active_job_batch_id", unique: true
    t.index ["finished_at"], name: "index_solid_queue_batches_on_finished_at"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "batch_id"
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["batch_id"], name: "index_solid_queue_jobs_on_batch_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "catalog_entries", "game_tables"
  add_foreign_key "catalog_entries", "sheet_templates"
  add_foreign_key "characters", "characters", column: "owner_character_id", on_delete: :nullify
  add_foreign_key "characters", "game_tables"
  add_foreign_key "characters", "participations"
  add_foreign_key "chat_messages", "game_tables", on_delete: :cascade
  add_foreign_key "chat_messages", "users", on_delete: :nullify
  add_foreign_key "friendships", "users", column: "addressee_id"
  add_foreign_key "friendships", "users", column: "requester_id"
  add_foreign_key "game_maps", "game_tables"
  add_foreign_key "game_maps", "map_templates", on_delete: :nullify
  add_foreign_key "game_tables", "game_maps", column: "board_game_map_id", on_delete: :nullify
  add_foreign_key "game_tables", "sheet_templates", on_delete: :nullify
  add_foreign_key "inventory_items", "characters"
  add_foreign_key "map_templates", "users", column: "owner_id"
  add_foreign_key "participations", "game_tables"
  add_foreign_key "participations", "users"
  add_foreign_key "sheet_templates", "sheet_templates", column: "parent_id"
  add_foreign_key "sheet_templates", "users", column: "owner_id"
  add_foreign_key "solid_queue_batch_executions", "solid_queue_batches", column: "batch_id", on_delete: :cascade
  add_foreign_key "solid_queue_batch_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
