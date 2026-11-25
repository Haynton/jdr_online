require "test_helper"

class LegalNoticeTest < ActionDispatch::IntegrationTest
  SRD_ATTRIBUTION = "This work includes material from the System Reference Document 5.2.1 (“SRD 5.2.1”) by " \
                    "Wizards of the Coast LLC, available at https://www.dndbeyond.com/srd. The SRD 5.2.1 is licensed " \
                    "under the Creative Commons Attribution 4.0 International License, available at " \
                    "https://creativecommons.org/licenses/by/4.0/legalcode.".freeze

  test "a visitor reads the legal notice, with the attribution of the SRD 5.2.1 word for word" do
    get legal_notice_path, headers: { "Accept-Language" => "fr" }

    assert_response :success
    assert_select "h1", text: "Mentions légales"
    assert_select "h2", text: "Éditeur du site"
    assert_select "a[href='mailto:contact@fumblequest.com']"
    assert_select "blockquote[lang=en]", text: SRD_ATTRIBUTION
    assert_select "blockquote[lang=en]", text: /ORC License held in the Library of Congress/
  end

  test "the attribution names Wizards of the Coast only once, as the SRD 5.2.1 asks" do
    get legal_notice_path

    assert_equal 1, response.body.scan("Wizards of the Coast").size
    assert_no_match(/D&amp;D|Dungeons/, response.body)
  end

  test "the home page links to the legal notice at its foot" do
    get root_path

    assert_select "footer a[href=?]", legal_notice_path
  end

  test "a signed in user finds the legal notice in a section of the settings" do
    sign_in User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")

    get settings_legal_notice_path

    assert_response :success
    assert_select "a[href=?][aria-current]", settings_legal_notice_path, text: "Mentions légales"
    assert_select "#settings-section-title", text: "Mentions légales"
    assert_select "h3", text: "Éditeur du site"
    assert_select "blockquote[lang=en]", text: SRD_ATTRIBUTION
  end
end
