require "test_helper"

class GameTableStreamsHelperTest < ActionView::TestCase
  test "a page listens to a table through its own channel, with a name signed for it" do
    game_master = User.create!(email: "gm@example.com", username: "maitre", password: TEST_PASSWORD)
    game_table = GameTableCreator.new(user: game_master, attributes: { name: "La Crypte" },
                                      sheet_template: SheetTemplate.create!(name: "Fantasy", locale: "fr")).call

    render html: game_table_stream_from(game_table, game_master_only: true)

    assert_select "turbo-cable-stream-source[channel=GameTableChannel]" do |sources|
      signed_stream_name = sources.first["signed-stream-name"]
      assert_equal "#{game_table.to_gid_param}:game_master",
                   Turbo.signed_stream_verifier.verified(signed_stream_name, purpose: GameTableChannel::SIGNATURE_PURPOSE)
    end
  end
end
