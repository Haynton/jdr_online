require "test_helper"

class PasswordResetEmailTest < ActionDispatch::IntegrationTest
  # Stands for an SMTP service that refuses every email (a wrong login, a blocked address)
  class RefusingDelivery
    def initialize(_settings); end

    def deliver!(_email)
      raise Net::SMTPAuthenticationError, "535 5.7.8 Authentication failed"
    end
  end

  ActionMailer::Base.add_delivery_method :refusing, RefusingDelivery

  setup do
    User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD)
  end

  test "the reset password email comes from the address of Fumble Quest" do
    assert_emails(1) { post user_password_path, params: { user: { email: "player@example.com" } } }
    reset_email = ActionMailer::Base.deliveries.last
    assert_equal ["noreply@fumblequest.com"], reset_email.from
    assert_equal ["player@example.com"], reset_email.to
  end

  test "an email that cannot leave shows a clear message in a floating bubble, the email kept in its field" do
    with_delivery_method(:refusing) do
      post user_password_path, params: { user: { email: "player@example.com" } },
                               headers: { "Accept-Language" => "fr" }
    end

    assert_response :service_unavailable
    assert_select "[data-controller=toast][role=alert]",
                  text: /L'e-mail n'a pas pu être envoyé. Réessayez dans quelques minutes./
    assert_select "input#user_email[value=?]", "player@example.com"
  end

  private

  def with_delivery_method(delivery_method)
    previous_method = ActionMailer::Base.delivery_method
    ActionMailer::Base.delivery_method = delivery_method
    yield
  ensure
    ActionMailer::Base.delivery_method = previous_method
  end
end
