require "test_helper"

class FriendRequestTest < ActiveSupport::TestCase
  setup do
    @luara = User.create!(email: "luara@example.com", username: "Luara", password: TEST_PASSWORD)
    @othna = User.create!(email: "othna@example.com", username: "othna", password: TEST_PASSWORD)
  end

  test "asking by username, whatever its case, makes a pending friendship" do
    friend_request = FriendRequest.new(requester: @luara, username: " OTHNA ")

    assert friend_request.save
    assert_predicate friend_request.friendship, :pending?
    assert_equal @othna, friend_request.friendship.addressee
    assert_not @luara.friend?(@othna)
  end

  test "asking back somebody who already asked accepts their request" do
    FriendRequest.new(requester: @othna, username: "Luara").save

    friend_request = FriendRequest.new(requester: @luara, username: "othna")

    assert_no_difference("Friendship.count") { assert friend_request.save }
    assert_predicate friend_request, :accepted_existing_request?
    assert @luara.friend?(@othna)
    assert_equal [@othna], @luara.friends.to_a
    assert_equal [@luara], @othna.friends.to_a
  end

  test "an unknown username, one's own, an existing friend or a request already sent are refused" do
    assert errors_for("personne").of_kind?(:username, :not_found)
    assert errors_for("Luara").of_kind?(:username, :oneself)

    FriendRequest.new(requester: @luara, username: "othna").save
    assert errors_for("othna").of_kind?(:username, :already_asked)

    @luara.sent_friendships.first.accepted!
    assert errors_for("othna").of_kind?(:username, :already_friends)
  end

  test "the database keeps one friendship per pair, whoever asked" do
    Friendship.create!(requester: @luara, addressee: @othna)

    assert_raises(ActiveRecord::RecordNotUnique) do
      Friendship.new(requester: @othna, addressee: @luara).save!(validate: false)
    end
  end

  test "deleting an account removes its friendships on both sides" do
    Friendship.create!(requester: @luara, addressee: @othna, status: :accepted)

    assert_difference("Friendship.count", -1) { @othna.destroy }
  end

  private

  def errors_for(username)
    FriendRequest.new(requester: @luara, username: username).tap(&:validate).errors
  end
end
