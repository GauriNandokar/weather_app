Rails.application.routes.draw do
  root to: 'weather#index'
  post 'forecast', to: 'weather#forecast', as: :forecast
end