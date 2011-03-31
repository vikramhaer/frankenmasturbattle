Masterater::Application.routes.draw do
  get "betas/confirmation"
  resources :betas, :only => ["new","create"]

  get "rankings/global"
  get "rankings/friends"
  get "rankings/groups"
  match "rankings" => "rankings#index"
  #match 'rankings/groups/:id' => 'groups#show'  DO THIS LATER

  resources :groups, :only => ["show"]

  # match "users/:id/all_friends" => "users#all_friends"        dep
  # match "users/:id/all_friends/:cmd" => "users#all_friends"   dep
  # get "user/index"                                            admin_data
  # get "user/create"                                           admin_data
  # get "user/destroy"                                          admin_data 
  resources :users, :only => ["show"]                          #admin_data


  match "/settings" => "users#settings"
  get "user/show"
  get "user/update_info"

  match "/about" => "home#about"
  match "/privacy" => "home#privacy"
  match "/battle_update" => "home#battle_update"
  match "/invite" => "home#invite"
  match "/invite_update" => "home#invite_update"

  #get "home/index"
  match "/battle" => "home#battle"

  root :to => "home#index"

  match "/auth/:provider/callback" => "sessions#create"

  match "/signout" => "sessions#destroy", :as => :signout

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
