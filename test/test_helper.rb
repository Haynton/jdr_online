ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
# Helpers shared by several tests (a template with spells: SpellTemplateBuilder)
Rails.root.glob("test/support/**/*.rb").each { |support_file| require support_file }

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Long enough for the 12 characters rule (config.password_length in config/initializers/devise.rb)
    TEST_PASSWORD = "correct-horse-battery".freeze
  end
end

module ActionDispatch
  class IntegrationTest
    include Devise::Test::IntegrationHelpers
  end
end
