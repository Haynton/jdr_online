require "test_helper"

# The picture of an account or of a character (HasAvatar): a PNG, JPEG or WebP of 2 MB at most, checked alone, the
# rest of the record saved as it was
class HasAvatarTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "aria@example.com", username: "Aria", password: TEST_PASSWORD, locale: "fr")
  end

  test "a picture is kept" do
    assert @user.change_avatar(picture("map.png"))

    assert_predicate @user.reload.avatar, :attached?
  end

  test "a file that is not a picture is refused, with its reason" do
    assert_not @user.change_avatar(Rack::Test::UploadedFile.new(file_fixture("notes.txt"), "text/plain"))

    assert_equal ["The picture must be a PNG, JPEG or WebP."], @user.errors.messages_for(:avatar)
    assert_not_predicate @user.reload.avatar, :attached?
  end

  test "a picture over 2 MB is refused" do
    oversized = Tempfile.new(["big", ".png"]).tap do |file|
      file.binmode
      file.write(file_fixture("map.png").binread + ("\0" * HasAvatar::AVATAR_MAX_SIZE))
      file.rewind
    end

    assert_not @user.change_avatar(Rack::Test::UploadedFile.new(oversized.path, "image/png"))
    assert_equal ["The picture must not exceed 2 MB."], @user.errors.messages_for(:avatar)
  ensure
    oversized&.close!
  end

  test "nothing sent asks for a picture" do
    assert_not @user.change_avatar(nil)

    assert_equal ["Choose a picture."], @user.errors.messages_for(:avatar)
  end

  test "only the picture is checked: a record that no longer passes its own validations still takes it" do
    @user.update_column(:username, "x")

    assert @user.change_avatar(picture("map.png"))
    assert_predicate @user.reload.avatar, :attached?
  end

  test "removed, the picture is gone" do
    @user.change_avatar(picture("map.png"))
    @user.remove_avatar

    assert_not_predicate @user.reload.avatar, :attached?
  end

  private

  def picture(name)
    Rack::Test::UploadedFile.new(file_fixture(name), "image/png")
  end
end
