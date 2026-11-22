require "test_helper"

class AcceptLanguageParserTest < ActiveSupport::TestCase
  test "reduces regional variants to their base language" do
    assert_equal %w[fr en], parse("fr-FR,en-GB;q=0.8")
  end

  test "orders languages by quality" do
    assert_equal %w[fr en], parse("en;q=0.5,fr;q=0.9")
  end

  test "keeps the header order when qualities are equal" do
    assert_equal %w[fr en], parse("fr,en")
  end

  test "drops languages refused with q=0" do
    assert_equal %w[en], parse("fr;q=0,en")
  end

  test "returns no language for a missing or empty header" do
    assert_empty parse(nil)
    assert_empty parse("")
  end

  test "lists each base language only once" do
    assert_equal %w[fr], parse("fr-FR,fr;q=0.9")
  end

  test "keeps a less preferred language after an unavailable one" do
    assert_equal %w[de en], parse("de-DE,de;q=0.9,en;q=0.8")
  end

  private

  def parse(header)
    Locales::AcceptLanguageParser.new(header).call
  end
end
