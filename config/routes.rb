Rails.application.routes.draw do
  root to: 'home#index'

  resources :weather_grid, only: [:index]
end
