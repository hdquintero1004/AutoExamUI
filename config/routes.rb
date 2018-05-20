Rails.application.routes.draw do
  resources :exams do
    member do
      get 'exam_version'
      get 'evaluate_answer'
      get 'generate_version'
      get 'select_questions'
      get 'show_pdf_file'
      get 'update_master'
      get 'update_json_master'
    end
  end
  resources :signatures do
    member do
      get 'search'
    end
  end


  resources :teachers
  resources :options
  resources :questions
  resources :roles

  devise_for :users

  get 'home/index'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'home#index'
end
