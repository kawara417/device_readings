Rails.application.routes.draw do
  resources :readings, only: [:create]
  resources :devices do
    get :latest_timestamp, :on => :member
    get :cumulative_count, :on => :member
  end
end
