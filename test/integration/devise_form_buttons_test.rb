require "test_helper"

class DeviseFormButtonsTest < ActionDispatch::IntegrationTest
  test "the sign up button is a primary button, without the Bootstrap class" do
    get new_user_registration_path

    assert_primary_submit_button
  end

  test "the account update button is a primary button, without the Bootstrap class" do
    sign_in User.create!(email: "player@example.com", password: TEST_PASSWORD)

    get edit_user_registration_path

    assert_primary_submit_button
  end

  test "the delete account button is a danger button and still asks for confirmation" do
    sign_in User.create!(email: "player@example.com", password: TEST_PASSWORD)

    get edit_user_registration_path

    assert_select "form[action=?] button[type=submit].bg-danger.text-white[data-turbo-confirm]",
                  user_registration_path, count: 1
  end

  private

  def assert_primary_submit_button
    assert_select "form input[type=submit].bg-primary.text-white.h-11", count: 1
    assert_select "form input[type=submit].btn", count: 0
  end
end
