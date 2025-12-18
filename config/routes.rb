Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  namespace :admin do
    resource :dashboard, only: :show
    resources :farmers do
      member do
        get :account_info
      end
    end
    resources :products do
      member do
        patch :update_stock
      end
    end
    resources :payments, only: [:index] do
      post :verify, on: :member
    end
    resources :orders, only: [:index] do
      member do
        post :confirm
        post :cancel
      end
    end
  end
  get "home/index"
  resource :admin_otp, only: %i[new create]
  get "/health", to: "health#show"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
end
