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
  get 'config/index'
  get 'delete', controller: 'application', action: 'render_404'
  delete 'delete' => 'deploy#delete'
  get 'setting_domain' => 'domain#new'
  post 'setting_domain' => 'domain#create'
  delete 'delete_domain' => 'domain#delete'
  get 'expand', controller: 'application', action: 'render_404'
  post 'expand' => 'deploy#expand'
  get 'create' => 'create_wizard#index'
  get 'create/step2', controller: 'application', action: 'render_404'
  post 'create/step2' => 'create_wizard#step2'
  get 'create/step3', controller: 'application', action: 'render_404'
  post 'create/step3' => 'create_wizard#step3'
  get 'create/step3', controller: 'application', action: 'render_404'
  post 'create/done' => 'create_wizard#done'
  get 'info_domain', controller: 'application', action: 'render_404'
  post 'info_domain' => 'domain#get_deploy_data'
end
