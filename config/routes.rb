Rails.application.routes.draw do
  resources :options
  resources :questions
  devise_for :users
  get 'home/index'

  resources :roles
  resources :signatures
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: "home#index"
end
