Rails.application.routes.draw do
  devise_for :users
  root to: 'home#index'

  resources :weather_grid, only: [:index]

  get '/subscriptions/cancel' => 'subscriptions#cancel'
  resources :subscriptions
end
