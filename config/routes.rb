Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  root "pokemons#random"

  # Pokemon routes
  get  "/pokemon/random", to: "pokemons#random"
  post "/pokemon/:id/catch", to: "pokemons#catch", as: :catch_pokemon

  # Caught Pokemon routes
  get  "/caught", to: "caught_pokemons#index"
  # JSON API
  namespace :api do
    resources :caught_pokemons, only: [:index]
  end
end
