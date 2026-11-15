require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "a password of 11 characters is too short" do
    user = build_user(password: "a" * 11)

    assert_not user.valid?
    assert user.errors.added?(:password, :too_short, count: 12)
  end

  test "a password of 12 characters is accepted" do
    assert build_user(password: "a" * 12).valid?
  end

  test "the username is required" do
    user = build_user(username: "")

    assert_not user.valid?
    assert user.errors.added?(:username, :blank)
    assert_not user.errors.added?(:username, :too_short, count: 3), "only one message for an empty username"
  end

  test "the username has 3 to 20 characters" do
    assert build_user(username: "abc").valid?
    assert build_user(username: "a" * 20).valid?
    assert username_errors("ab").added?(:username, :too_short, count: 3)
    assert username_errors("a" * 21).added?(:username, :too_long, count: 20)
  end

  test "the username accepts letters with accents, digits, dashes and underscores" do
    assert build_user(username: "Gaël_le-Barde42").valid?
  end

  test "the username refuses spaces and other characters" do
    ["le barde", "barde!", "barde@home"].each do |refused_username|
      assert username_errors(refused_username).of_kind?(:username, :invalid), refused_username
    end
  end

  test "the spaces around the username are removed" do
    assert_equal "barde", build_user(username: "  barde ").username
  end

  test "two players cannot have the same username, whatever the capitals" do
    build_user(username: "Barde").save!

    other_user = build_user(username: "barde", email: "other.player@example.com")
    assert_not other_user.valid?
    assert other_user.errors.added?(:username, :taken, value: "barde")
  end

  test "the initials are the first two letters of the username, in capitals" do
    assert_equal "PL", User.new(username: "player").initials
  end

  test "the initials skip the dashes and underscores of the username" do
    assert_equal "JD", User.new(username: "_j-doe").initials
  end

  private

  def username_errors(username)
    build_user(username: username).tap(&:validate).errors
  end

  def build_user(username: "player", email: "player@example.com", password: TEST_PASSWORD)
    User.new(username: username, email: email, password: password, password_confirmation: password)
  end
end
