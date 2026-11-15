class AddUsernameToUsers < ActiveRecord::Migration[8.1]
  # A copy of the table, independent of the User model: this migration must still run when the model changes
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  # Leaves room for a number added at the end when two email names give the same username
  BASE_USERNAME_MAX_LENGTH = 16

  def up
    add_column :users, :username, :string
    give_existing_users_a_username
    change_column_null :users, :username, false
    # On lower(username): "Julien" and "julien" are the same username
    add_index :users, "lower(username)", unique: true, name: "index_users_on_lower_username"
  end

  def down
    remove_index :users, name: "index_users_on_lower_username"
    remove_column :users, :username
  end

  private

  def give_existing_users_a_username
    taken_usernames = []
    MigrationUser.find_each do |user|
      username = first_free_username(username_from_email(user.email), taken_usernames)
      taken_usernames << username.downcase
      user.update_columns(username: username)
    end
  end

  # Keeps the allowed characters of the email name, padded to the minimum length of 3
  def username_from_email(email)
    email_name = email.split("@").first.to_s.gsub(/[^[:alnum:]_-]/, "")
    email_name.ljust(3, "_").first(BASE_USERNAME_MAX_LENGTH)
  end

  def first_free_username(base_username, taken_usernames)
    candidate = base_username
    number = 1
    while taken_usernames.include?(candidate.downcase)
      number += 1
      candidate = "#{base_username}#{number}"
    end
    candidate
  end
end
