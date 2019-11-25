Rails.application.routes.draw do
  #devise_for :users, only: [:sessions]
  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }

  namespace :admin do
    root "console#index"
    resources :deploy, :except => [:new, :create, :destroy]
    get 'pod' => "console#pod"
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root "top#index"
  get 'status/show'
  get 'status/user'
  get 'config/index'
  get 'create' => 'create#new'
  post 'create' => 'deploy#create'
  get 'delete', controller: 'application', action: 'render_404'
  delete 'delete' => 'deploy#delete'
  get 'setting_domain' => 'domain#create'
  delete 'delete_domain' => 'domain#delete'
  get 'expand', controller: 'application', action: 'render_404'
  post 'expand' => 'deploy#expand'
end
