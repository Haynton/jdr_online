require "test_helper"

class ConfirmDialogTest < ActionDispatch::IntegrationTest
  setup do
    sign_in User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
  end

  test "a signed in page holds the confirmation window, named by its question, with both button looks written out" do
    get game_tables_path

    assert_select "dialog#confirm-dialog[aria-labelledby=confirm-dialog-question][data-default-label=?]", "Confirmer" do
      assert_select "form[method=dialog] p#confirm-dialog-question"
      assert_select "button[value=cancel]", text: "Annuler"
      assert_select "button[value=confirm][data-confirm-dialog-button]"
    end
    assert_select "dialog#confirm-dialog[data-primary-classes*='bg-primary'][data-danger-classes*='bg-danger']"
  end

  test "log out asks first, its confirm button saying the action" do
    get game_tables_path

    assert_select "form[action=?][data-turbo-confirm=?][data-confirm-button=?]", destroy_user_session_path,
                  "Se déconnecter ?", "Se déconnecter"
  end

  test "deleting the account asks first, with a red confirm button" do
    get settings_account_path

    assert_select "form[action=?] button[data-turbo-confirm][data-confirm-button=?][data-confirm-variant=danger]",
                  user_registration_path, "Supprimer"
  end

  test "a visitor page has no confirmation window" do
    sign_out :user
    get root_path

    assert_select "dialog#confirm-dialog", count: 0
  end
end
