Rails.application.routes.draw do
  resources :exams do
    member do
      get 'select_questions'
    end
  end
  resources :teachers
  resources :options
  resources :questions
  resources :signatures
  resources :roles

  devise_for :users

  get 'home/index'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'home#index'
end
