module Users
  class PasswordsController < Devise::PasswordsController
    include DeviseLocale
    include ScreenReaderNotice
  end
end
