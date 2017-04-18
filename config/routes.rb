Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'spaces#index'

  resources :spaces
  resources :topics
  get 'topics/list_topic/:id' => 'topics#list_topic'

end
