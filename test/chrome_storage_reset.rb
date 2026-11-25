require "capybara/selenium/driver"
require "capybara/selenium/driver_specializations/chrome_driver"

# Between two system tests, Capybara 3.40.0 (its latest version) empties the cookies and the local storage of every
# site at once, by sending Chrome the origin "*". The Chrome of the GitHub image ubuntu-24.04 of 22 November 2026
# refuses it ("invalid argument: * is not a valid URL"), and every system test failed. The same emptying is asked for
# the server of the tests, the only site they open. To remove when a version of Capybara no longer sends "*"
module ChromeStorageReset
  EVERY_ORIGIN = "*".freeze

  def execute_cdp(command, params = {})
    return super unless command == "Storage.clearDataForOrigin" && params[:origin] == EVERY_ORIGIN

    test_server = Capybara.current_session.server
    return unless test_server

    super(command, params.merge(origin: test_server.base_url))
  end
end

Capybara::Selenium::Driver::ChromeDriver.prepend(ChromeStorageReset)
