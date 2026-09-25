Rails.application.routes.draw do
  # Auth
  resource :session
  resources :passwords, param: :token
  resources :users, only: [ :new, :create ]

  # Back-office (rutas actuales)
  root "dashboard#index"
  get "dashboard", to: "dashboard#index"

  resources :products
  resources :batches do
    resources :stock_movements, only: [ :new, :create ]
  end
  resources :stock_movements, only: [ :index ]
  resources :suppliers
  resources :purchase_orders

  # API v1
  namespace :api do
    namespace :v1 do
      post "login", to: "sessions#create"
      delete "logout", to: "sessions#destroy"
      get "profile", to: "users#profile"

      resources :products, only: [ :index, :show ]
      resources :batches, only: [ :index, :show ]
      resources :stock_movements, only: [ :index, :create ]
      resources :suppliers, only: [ :index, :show ]
    end
  end

  # Mailer
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
