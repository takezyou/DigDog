Rails.application.routes.draw do
  #devise_for :users, only: [:sessions]
  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }

  namespace :admin do
    root "console#index"
    get 'deploy' => "console#deploy"
    get 'admin' => "console#admin"
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root "top#index"
  get 'status/show'
  get 'status/user'
  get 'create' => 'create#new'
  get 'create/state', controller: 'application', action: 'render_404'
  post 'create/state' => 'create#state'
  get 'delete', controller: 'application', action: 'render_404'
  post 'delete' => 'status#delete'
  delete 'delete' => 'status#delete'
end
