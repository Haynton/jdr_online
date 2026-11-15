require "test_helper"

class DeviseFormButtonsTest < ActionDispatch::IntegrationTest
  test "the sign up button is a primary button, without the Bootstrap class" do
    get new_user_registration_path

    assert_select "form input[type=submit].bg-primary.text-white.h-11", count: 1
    assert_select "form input[type=submit].btn", count: 0
  end
end
