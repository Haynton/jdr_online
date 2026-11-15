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

  test "the initials are the first two letters of the email name, in capitals" do
    assert_equal "PL", User.new(email: "player@example.com").initials
  end

  test "the initials skip the dots and dashes of the email name" do
    assert_equal "JD", User.new(email: "j.doe@example.com").initials
  end

  private

  def build_user(password:)
    User.new(email: "player@example.com", password: password, password_confirmation: password)
  end
end
