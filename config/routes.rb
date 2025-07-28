Rails.application.routes.draw do
  root to: 'pages#home'
  # as a user, i can see all of my kanji
  # /api/v1/kanjis
  # get '/api/v1/cafes'
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :kanjis, only: [ :index, :show ]
    end
  end

  # as a user, can search through all of my kanji
  # as a user, i can add a kanji
end
