Rails.application.routes.draw do
  devise_for :users, controllers: {
    passwords: "users/passwords",
    registrations: "users/registrations",
    sessions: "users/sessions"
  }
  root to: "pages#home"
  get "legal", to: "legal_notices#show", as: :legal_notice
  resources :game_tables, only: %i[index new create show edit destroy] do
    # The steps of the creation of a draft (app/controllers/game_tables/). The first one of a new table is
    # GameTablesController#new; the maps come with their milestone
    scope module: :game_tables do
      resource :details, only: %i[edit update]
      # The settings that depend on the template chosen (the starting level), right after it
      resource :settings, only: %i[edit update]
      # The spells and items the table customizes, from the catalog of its template (Catalogs::TableCustomizations)
      resource :catalog, only: %i[edit update]
      # The whole catalog of its template, in a window: an entry picked is listed (copied for the table)
      resource :catalog_picker, only: :show
      # Its changes applied to the characters already made (their copies of the spells and items)
      resource :catalog_application, only: :create
      # One spell or item of that catalog, in a window: seen and changed for the table (its copy, same key), or added;
      # its switch offers it to the players or turns it off (offer)
      resources :catalog_entries, only: %i[new create edit update destroy], param: :key do
        resource :offer, only: :update, controller: "catalog_offers"
      end
      # The NPCs and enemies of the table: the step lists them (cast), each one opens in a window (npcs), added from
      # the bestiary of the catalog (copied) or from nothing
      resource :cast, only: %i[edit update]
      resources :npcs, only: %i[new create edit update destroy]
      resource :bestiary, only: :show
      # The maps of the table: the step lists them (map_list), each one copied from « Mes cartes » (maps), changed in
      # the map editor (its drawing and its picture saved like those of a map of « Mes cartes »), or, sent as an image
      # before the editor, in a window
      resource :map_list, only: %i[edit update]
      resources :game_maps, only: %i[new create edit update destroy], path: "maps" do
        resource :layout, only: :update, module: :game_maps
        resource :picture, only: %i[create destroy], module: :game_maps
        resources :creatures, only: :create, module: :game_maps
      end
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
      # draft: the step saved in the background while it is filled (autosave_controller.js)
      resources :character_steps, only: %i[show update], path: "character/steps", param: :step do
        patch :draft, on: :member
      end
      # The picture of that character while it is made: the draft is saved first if it was not yet
      resource :character_avatar, only: %i[update destroy], path: "character/avatar", controller: "/characters/avatars"
      # "Roll the dice" of the abilities on that sheet: the server rolls, nothing is stored (JSON)
      resource :ability_roll, only: :create
      # "Roll the hit dice" on the summary of that character: the server rolls once and keeps the results
      resource :hit_dice_roll, only: :create
      # The sheet of a character from the game room, in its window: any player's for the game master, their own for a
      # player
      resources :character_sheets, only: :show
      # The game master gives an item of the catalog of the table to a player, from the game room
      resource :item_gift, only: :create
    end
  end
  # The invitation link given to the players: the page shows the table, join makes the user a player
  resources :invitations, only: :show, param: :token do
    post :join, on: :member
  end
  # The characters of a player on all their tables (« Mes personnages »): the list, the sheet of one of them, and its
  # identity and description changed once it is complete
  resources :characters, only: %i[index show edit update] do
    # Its picture, changed on its page "Change" (complete)
    resource :avatar, only: %i[update destroy], module: :characters
  end

  # The maps of a game master (« Mes cartes »), drawn in the map editor
  resources :map_templates, only: %i[index create edit update destroy] do
    resource :layout, only: :update, module: :map_templates
    resource :picture, only: %i[create destroy], module: :map_templates
  end

  # The templates of a game master (the template editor): the list (theirs, then the predefined ones), the page of
  # one of them (rename, delete), and "Duplicate", which makes one of theirs from another
  resources :sheet_templates, only: %i[index show update destroy] do
    resource :duplicate, only: :create, module: :sheet_templates
    # The fields of the character sheet, by section, then the form of one of them (named by its key)
    resources :fields, only: %i[index edit update], module: :sheet_templates, param: :key
    # The name of a creation step, the only change of a step in a template duplicated from a working one (its steps
    # and their order stay: its computing rules rely on them)
  end

  # What waits for an answer (the bell of the navigation): friend requests, invitations to a table
  resource :notifications, only: :show

  # Settings: one address per section, so the section menu is made of plain links
  get "settings", to: "settings/sections#index", as: :settings
  namespace :settings do
    resource :display, only: :show
    resource :locale, only: :update
    resource :account, only: :show
    resource :avatar, only: %i[update destroy]
    resource :username, only: :update
    resource :email, only: :update
    # The friends, the requests received and sent. A friendship is asked (create), accepted by the user asked
    # (update), then refused, cancelled or removed (destroy)
    resource :friends, only: :show
    resources :friendships, only: %i[create update destroy]
    resources :friend_suggestions, only: :index
    resource :security, only: :show
    resource :password, only: :update
    resource :legal_notice, only: :show
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
