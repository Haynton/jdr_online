require "test_helper"
require_relative "chrome_storage_reset"

# Selenium Manager (run by selenium-webdriver to find chromedriver) sends usage statistics to
# plausible.io on every run unless this is set. It inherits the environment of the tests
ENV["SE_AVOID_STATS"] = "true"

# Between two system tests, Capybara (3.40, Chrome) clears cookies and localStorage of the server
# of the tests (Storage.clearDataForOrigin in its Chrome driver reset, see chrome_storage_reset.rb):
# a theme chosen in one test never leaks into the next one, so no setup is needed to clear it.
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 900]
end
