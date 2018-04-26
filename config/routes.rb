Rails.application.routes.draw do
  get 'view/:name/:period', to: 'projects#view', as: 'view'
  get 'refresh/:name/:period', to: 'projects#refresh', as: 'refresh'
  root 'projects#index'
end
