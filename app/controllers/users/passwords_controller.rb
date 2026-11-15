module Users
  class PasswordsController < Devise::PasswordsController
    include DeviseLocale
  end
end
