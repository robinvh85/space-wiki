Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'spaces#index'

  resources :spaces

  get 'search' => 'topics#search'
  get 'topics/list_topic/:id' => 'topics#list_topic'
  resources :topics

  get 'galleries/list/:topic_id'	=> 'galleries#list'
  resources :galleries

  get 'subjects/list' => 'subjects#list'  
  resources :subjects

  get 'test/list'	=> 'test#list'
  resources :test

  get 'change_subject/:id' => 'application#change_subject'
  get 'change_root_topic/:id' => 'application#change_root_topic'
  get 'default_values' => 'application#default_values'

  resources :current_orders

end
