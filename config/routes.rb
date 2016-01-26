Rails.application.routes.draw do
  devise_for :users
  root to: 'home#index'

  resources :weather_grid, only: [:index]

  get '/subscriptions/cancel', to: 'subscriptions#cancel'
  get 'subscriptions/update_card', to: 'subscriptions#update_card'
  post 'subscriptions/update_card_details', to: 'subscriptions#update_card_details'
  resources :subscriptions
end
