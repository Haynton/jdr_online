# A player invited by their username takes part only once they accept: until then their participation is pending.
# Every participation made before is accepted (default), and the database only allows the two values
class AddStatusToParticipations < ActiveRecord::Migration[8.1]
  def change
    add_column :participations, :status, :string, null: false, default: "accepted"
    add_check_constraint :participations, "status IN ('accepted', 'pending')", name: "participations_status_check"
  end
end
