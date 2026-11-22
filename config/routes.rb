Rails.application.routes.draw do
  devise_for :users, controllers: {
    passwords: "users/passwords",
    registrations: "users/registrations",
    sessions: "users/sessions"
  }
  root to: "pages#home"
  resources :game_tables, only: %i[index new create show edit] do
    # The steps of the creation of a draft (app/controllers/game_tables/). The first one of a new table is
    # GameTablesController#new; NPCs and maps come with their milestone
    scope module: :game_tables do
      resource :details, only: %i[edit update]
      # The summary holds the invitation link, and a new link replaces it from there
      resource :summary, only: %i[show update]
      resource :invite_token, only: :update
      # Invited by their username, from the summary (the id of destroy is the one of the participation)
      resources :player_invitations, only: %i[create destroy]
      # Usernames suggested while typing the one to invite (JSON)
      resources :player_suggestions, only: :index
      # The invited player answers from "My tables": accept (update) or decline (destroy)
      resource :invitation_answer, only: %i[update destroy]
      # The character of the player, made before joining the game: new leads to the step to fill in, then each step
      # of the creation shows and saves the draft (/game_tables/:id/character/steps/:step, CharacterCreationSteps)
      resource :character, only: :new
      resources :character_steps, only: %i[show update], path: "character/steps", param: :step
      # "Roll the dice" of the abilities on that sheet: the server rolls, nothing is stored (JSON)
      resource :ability_roll, only: :create
    end
  end
  # The invitation link given to the players: the page shows the table, join makes the user a player
  resources :invitations, only: :show, param: :token do
    post :join, on: :member
  end
  # The templates of a game master (the template editor): the list (theirs, then the predefined ones), the page of
  # one of them (rename, delete), and "Duplicate", which makes one of theirs from another
  resources :sheet_templates, only: %i[index show update destroy] do
    resource :duplicate, only: :create, module: :sheet_templates
    # The fields of the character sheet, by section, then the form of one of them (named by its key)
    resources :fields, only: %i[index edit update], module: :sheet_templates, param: :key
  end

  # Settings: one address per section, so the section menu is made of plain links
  get "settings", to: "settings/sections#index", as: :settings
  namespace :settings do
    resource :display, only: :show
    resource :locale, only: :update
    resource :account, only: :show
    resource :username, only: :update
    resource :email, only: :update
    resource :security, only: :show
    resource :password, only: :update
  end

  # Component gallery to review the design system in both themes. Never routed in production
  get "dev/components", to: "dev/components#show", as: :dev_components if Rails.env.local?
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
