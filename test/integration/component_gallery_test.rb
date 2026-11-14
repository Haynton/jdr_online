require "test_helper"

class ComponentGalleryTest < ActionDispatch::IntegrationTest
  teardown do
    Rails.application.reload_routes!
  end

  test "the gallery is reachable in development and test, without signing in" do
    get dev_components_path

    assert_response :success
    assert_select "h1", text: "Component gallery"
  end

  # Minitest 6 no longer ships minitest/mock, so the environment is switched for real
  # and always put back in ensure, even if an assertion fails
  test "the gallery is not routed in production" do
    original_environment = Rails.env
    Rails.env = "production"
    Rails.application.reload_routes!

    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/dev/components")
    end
  ensure
    Rails.env = original_environment
  end
end
