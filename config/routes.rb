Rails.application.routes.draw do
  devise_for :users

  # Monolith routes
  root to: "home#index"
  resources :organization
  resources :roles
  resources :clock_events, only: [:create]

  # API routes
  namespace :api do
    namespace :v1 do
      post 'login', to: 'sessions#login'
      resources :organisations, only: [] do
        resources :clock_events, only: [:create]
      end
    end
  end
end
