Rails.application.routes.draw do
  devise_for :users, only: [:sessions]
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root "top#index"
  get 'status/show'
end
