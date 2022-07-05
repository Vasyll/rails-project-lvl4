# frozen_string_literal: true

Rails.application.routes.draw do
  root 'home#index'

  scope module: :web do
    get 'auth/:provider/callback', to: 'auth#callback', as: :callback_auth
    get 'auth/logout', to: 'auth#logout'
    post 'auth/:provider', to: 'auth#request', as: :auth_request

    resources :repositories, only: %i[index show new create] do
      resources :checks, only: %w[show create], module: 'repositories'
    end
  end

  namespace :api do
    resources :checks, only: %w[create]
  end
end
