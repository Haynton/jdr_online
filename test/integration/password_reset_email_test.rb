require "test_helper"

class PasswordResetEmailTest < ActionDispatch::IntegrationTest
  test "the reset password email comes from the address of Fumble Quest" do
    User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD)

    assert_emails(1) { post user_password_path, params: { user: { email: "player@example.com" } } }
    reset_email = ActionMailer::Base.deliveries.last
    assert_equal ["noreply@fumblequest.com"], reset_email.from
    assert_equal ["player@example.com"], reset_email.to
  end
end
