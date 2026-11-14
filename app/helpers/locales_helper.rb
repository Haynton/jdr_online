module LocalesHelper
  def locale_options
    I18n.available_locales.map { |locale| [t("locale_names.#{locale}"), locale.to_s] }
  end
end
