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
    resources :orders, only: [:index, :show] do
      member do
        post :confirm
        post :cancel
        patch :update_note
      end
    end
  end

  namespace :farmers do
    resource :dashboard, only: :show
    resources :products
    resources :orders, only: [:index, :show] do
      member do
        post :approve
        post :reject
      end
    end
    resource :profile, only: [:show, :edit, :update]
  end
  get "home/index"
  resource :admin_otp, only: %i[new create]
  get "/health", to: "health#show"

  # Public routes
  get "/farmer/approvals/:token", to: "farmer_order_approvals#show", as: :farmer_approval
  post "/farmer/approvals/:token/approve", to: "farmer_order_approvals#approve", as: :approve_farmer_approval
  post "/farmer/approvals/:token/reject", to: "farmer_order_approvals#reject", as: :reject_farmer_approval

  resources :products, only: [:index, :show]
  resources :farmers, only: [:show] do
    resources :products, only: [:index]
  end

  # Cart routes
  resource :cart, only: [:show], controller: 'carts'
  resources :cart_items, only: [:create, :update, :destroy], controller: 'carts' do
    collection do
      delete :destroy_all
    end
  end

  # Order routes
  resources :orders, only: [:index, :show, :new, :create] do
    collection do
      get :complete
    end
    member do
      post :report_payment
      post :cancel
    end
  end
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
