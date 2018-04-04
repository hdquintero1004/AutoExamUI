Rails.application.routes.draw do
  resources :exams do
    member do
      get 'exam_version'
      get 'generate_latex'
      get 'select_questions'
      get 'update_master'
      get 'update_json_master'
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
