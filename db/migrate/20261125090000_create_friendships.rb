class CreateFriendships < ActiveRecord::Migration[8.1]
  def change
    create_table :friendships do |t|
      t.references :requester, null: false, foreign_key: { to_table: :users }
      t.references :addressee, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "pending"
      t.timestamps

      t.check_constraint "status IN ('pending', 'accepted')", name: "friendships_status_check"
      t.check_constraint "requester_id <> addressee_id", name: "friendships_not_oneself_check"
    end

    # One friendship per pair of users, whoever asked: A asking B and B asking A are the same pair
    add_index :friendships, "LEAST(requester_id, addressee_id), GREATEST(requester_id, addressee_id)",
              unique: true, name: "index_friendships_one_per_pair"
  end
end
