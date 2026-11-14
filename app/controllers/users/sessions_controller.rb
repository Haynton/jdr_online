module Users
  class SessionsController < Devise::SessionsController
    include DeviseLocale
  end
end
