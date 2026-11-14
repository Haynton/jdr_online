# Turns "de-DE,de;q=0.9,en;q=0.8" into ["de", "en"]: base languages, most preferred first.
class AcceptLanguageParser
  AcceptedLanguage = Data.define(:code, :quality, :position)

  def initialize(header)
    @header = header.to_s
  end

  def call
    accepted_languages
      .select { |language| language.quality.positive? }
      .sort_by { |language| [-language.quality, language.position] }
      .map(&:code)
      .uniq
  end

  private

  def accepted_languages
    language_ranges.each_with_index.map do |language_range, position|
      parse_language_range(language_range, position)
    end
  end

  def language_ranges
    @header.split(",").map(&:strip).reject(&:empty?)
  end

  def parse_language_range(language_range, position)
    tag, *parameters = language_range.split(";").map(&:strip)
    AcceptedLanguage.new(code: base_language(tag), quality: quality_from(parameters), position: position)
  end

  def base_language(tag)
    tag.to_s.split("-").first.to_s.downcase
  end

  def quality_from(parameters)
    quality_parameter = parameters.find { |parameter| parameter.start_with?("q=") }
    return 1.0 if quality_parameter.nil?

    Float(quality_parameter.delete_prefix("q="), exception: false) || 0.0
  end
end
