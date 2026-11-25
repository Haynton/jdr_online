require "test_helper"

# The avatar of the account (Settings › Account) and the picture of a character (first step of its creation, its page
# "Change"): sent, refused with a reason, removed; a character's only by its player
class AvatarsTest < ActionDispatch::IntegrationTest
  setup do
    game_master = User.create!(email: "julien@example.com", username: "Julien", password: TEST_PASSWORD)
    @player = User.create!(email: "player@example.com", username: "player", password: TEST_PASSWORD, locale: "fr")
    sheet_template = EquipmentSpellsTemplateBuilder.create_template
    @game_table = GameTable.create!(name: "La Crypte", status: GameTable::READY_STATUS, sheet_template: sheet_template,
                                    template_snapshot: sheet_template.snapshot)
    @game_table.participations.create!(user: game_master, role: :game_master)
    participation = @game_table.participations.create!(user: @player, role: :player)
    @character = participation.create_character!(game_table: @game_table, kind: :pc, status: :complete, name: "Aria",
                                                 sheet: { "class" => "Mage" })
    sign_in @player
  end

  test "the account section offers to choose an avatar, the initials shown until then" do
    get settings_account_path

    assert_select "#account-avatar input[type=file][name=?][form=account-avatar-form]", "user[avatar]"
    assert_select "#account-avatar form#account-avatar-form[action=?]", settings_avatar_path
    assert_select "#account-identity span", text: "PL"
  end

  test "an avatar sent shows in the navigation, and can be removed" do
    patch settings_avatar_path, params: { user: { avatar: picture("map.png") } }

    assert_redirected_to settings_account_path
    follow_redirect!
    assert_select "#account-identity img"
    assert_select "button[form=account-avatar-remove-form]"

    delete settings_avatar_path
    follow_redirect!
    assert_select "#account-identity img", count: 0
  end

  test "a file that is not a picture is refused with its reason, in the account section" do
    patch settings_avatar_path, params: { user: { avatar: picture("notes.txt") } }

    assert_response :unprocessable_content
    assert_select "#account-avatar [role=alert]", text: "L'image doit être en PNG, JPEG ou WebP."
    assert_not_predicate @player.reload.avatar, :attached?
  end

  test "the picture of a character is sent from the page and the picker comes back, without leaving it" do
    patch character_avatar_path(@character), params: { character: { avatar: picture("map.png") } }, as: :turbo_stream

    assert_response :success
    assert_select "turbo-stream[action=replace][target=character-avatar-body]"
    assert_predicate @character.reload.avatar, :attached?
  end

  test "a refused picture of a character says why in the picker" do
    patch character_avatar_path(@character), params: { character: { avatar: picture("notes.txt") } },
                                             as: :turbo_stream

    assert_response :unprocessable_content
    assert_includes response.body, "L&#39;image doit être en PNG, JPEG ou WebP."
  end

  test "without JavaScript, the picture of a character brings back to its page" do
    patch character_avatar_path(@character), params: { character: { avatar: picture("map.png") } }

    assert_redirected_to character_path(@character)
  end

  test "the picture shows on the sheet and the card, and is removed from its page" do
    @character.change_avatar(picture("map.png"))

    get characters_path
    assert_select "a[href=?] img[src*=?]", character_path(@character), "map.png"
    get character_path(@character)
    assert_select "section img[src*=?]", "map.png"

    delete character_avatar_path(@character), as: :turbo_stream
    assert_not_predicate @character.reload.avatar, :attached?
  end

  test "the page Change offers the picture above its form, not inside it" do
    get edit_character_path(@character)

    assert_select "#character-avatar form#character-avatar-form"
    assert_select "form[action=?] #character-avatar", character_path(@character), count: 0
  end

  # The template of the test asks the name at its last step (description), in sections without described choices:
  # the picture sits above the fields
  test "the step that asks the name offers the picture, its forms outside the form of the step" do
    @character.update!(status: :draft, creation_step: "description")
    get game_table_character_step_path(@game_table, "description")

    assert_select "main form input[type=file][form=character-avatar-form]"
    assert_select "main form form", count: 0
    assert_select "body > form#character-avatar-form"
  end

  test "a picture sent before the first Continue saves the draft with it" do
    @character.destroy!

    patch game_table_character_avatar_path(@game_table), params: { character: { avatar: picture("map.png") } },
                                                         as: :turbo_stream

    draft = @player.characters.sole
    assert_predicate draft, :draft?
    assert_predicate draft.avatar, :attached?
  end

  test "the picture of another player's character is out of reach" do
    other = User.create!(email: "other@example.com", username: "other", password: TEST_PASSWORD)
    sign_in other

    patch character_avatar_path(@character), params: { character: { avatar: picture("map.png") } }

    assert_response :not_found
    assert_not_predicate @character.reload.avatar, :attached?
  end

  private

  def picture(name)
    fixture_file_upload(name, name.end_with?(".png") ? "image/png" : "text/plain")
  end
end
