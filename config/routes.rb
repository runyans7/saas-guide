Rails.application.routes.draw do
  devise_for :users
  root to: 'home#index'

  resources :weather_grid, only: [:index]
end
