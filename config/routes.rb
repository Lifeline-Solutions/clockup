Rails.application.routes.draw do
  devise_for :users

  # Monolith routes
  root to: "home#index"
  # Align routes with British spelling and existing controller
  resources :organisations, controller: "organisation" do
    # Nested user creation to avoid Devise route conflicts
    resources :users, only: [:new, :create]
  end
  # Keep top-level users for show only
  resources :users, only: [:show]
  resources :roles
  resources :clock_events, only: [:create]

  # API routes (versioned)
  namespace :api do
    namespace :v1 do
      post "login", to: "sessions#login"
      post "clock", to: "clock_events#create"
    end
  end
end
