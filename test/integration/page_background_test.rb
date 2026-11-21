require "test_helper"

# The pages under a large cover sit on the deeper night (page-deep), the others on the plain page color
class PageBackgroundTest < ActionDispatch::IntegrationTest
  test "my tables ask for the deep background" do
    sign_in User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD)
    get game_tables_path

    assert_select "body.bg-page-deep"
  end

  test "a plain page keeps the page color" do
    sign_in User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD)
    get settings_display_path

    assert_select "body.bg-page"
    assert_select "body.bg-page-deep", count: 0
  end
end
