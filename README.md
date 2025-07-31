## Kanji go API

<img width="1093" height="769" alt="Screenshot 2025-07-28 at 12 48 31 PM" src="https://github.com/user-attachments/assets/a13c7217-151d-47e5-b339-be3e3ae5b010" />


## Built With
- [Rails 7](https://guides.rubyonrails.org/) - Backend / Front-end
- [PostgreSQL](https://www.postgresql.org/) - Database
- [Heroku](https://heroku.com/) - Deployment

## Getting Started
### Setup

## Create API App
```
rails new kanji-api --api -d postgresql
cd kanji-api
rails db:create
```
## Create Github repository
```
gh repo create --public --source=.
```

## Essentials Gems Used

> gem 'devise'
> 
> gem 'pundit'
> 
> gem 'devise-jwt'
> 
> gem 'rack-cors'


## Install Devise
Add gem
```
gem 'devise'
```
Install gem
```
bundle install
```
Install devise
```
rails generate devise:install
```
Generate User Model with Devise
```
rails generate devise User first_name:string last_name:string
```

## Create Kanji Model
```
rails generate model Kanji \
  character:string \
  meanings:string \
  onyomi:string \
  kunyomi:string \
  name_readings:string \
  notes:string \
  heisig_en:string \
  stroke_count:integer \
  grade:integer \
  jlpt_level:integer \
  freq_mainichi_shinbun:integer \
  unicode:string
```
Update Model for using array
```
  t.string :meanings, array: true, default: []
  t.string :onyomi, array: true, default: []
  t.string :kunyomi, array: true, default: []
  t.string :name_readings, array: true, default: []
  t.string :notes, array: true, default: []
```

## Create UserKanji Model
```
rails generate model UserKanji \
  user:references \
  kanji:references \
  last_reviewed_at:datetime
```

## Run Migrations
```
rail db:migrate
```

## Set Model Associations
app/models/kanji.rb
```
class Kanji < ApplicationRecord
  has_many :user_kanjis, dependent: :destroy
  has_many :users, through: :user_kanjis
end
```
app/models/user.rb
```
class User < ApplicationRecord
  has_many :user_kanjis
  has_many :kanjis, through: :user_kanjis
end
```
## Create Controllers
Kanjis Controller
```
rails generate controller api/v1/kanjis
```
User_Kanjis Controller
```
rails generate controller api/v1/user_kanjis
```
## Add controller Routes
```
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :kanjis, only: [ :index ]
    end
  end
```

## Update Controllers
app/api/v1/kanjis_controller.rb
This makes it so you can search a specific kanji and returns json, for example character http://localhost:3000/api/v1/kanjis?character=家
Be sure to install JSONVue chrome extension so the return json is more human readable to the eye.
```
  def index
    @kanjis = Kanji.all
    if params[:character].present?
      @kanjis = Kanji.where('character ILIKE ?', "%#{params[:character]}%")
    else
      @kanjis = Kanji.all
    end
    render json: @kanjis
  end
```
At this point your kanji database and is ready for localhost testing, you can add your own data or you can import data from another free source API https://kanjiapi.dev/
Follow the next step that will show import rake, CORS and deployment to Heroku.

## Rake from another API
Create /lib/tasks/import_kanji.rake file
```
touch lib//tasks/import_kanji.rake
```
This will rake from https://kanjiapi.dev/ and import into your database
This can take a while since it's raking 13,000 Kanji's.

```
namespace :import do
  desc "Import kanji data from kanjiapi.dev"
  task kanji: :environment do
    require 'net/http'
    require 'json'

    puts "📦 Fetching full kanji list..."
    url = URI("https://kanjiapi.dev/v1/kanji/all")
    response = Net::HTTP.get(url)
    kanji_list = JSON.parse(response)

    puts "📄 Retrieved #{kanji_list.size} kanji. Importing..."

    kanji_list.each_with_index do |character, index|
      print "⛏️  [#{index + 1}/#{kanji_list.size}] #{character} ... "

      kanji_url = URI("https://kanjiapi.dev/v1/kanji/#{URI.encode_www_form_component(character)}")
      kanji_response = Net::HTTP.get(kanji_url)
      data = JSON.parse(kanji_response)

      Kanji.create_with(
        meanings: data["meanings"],
        onyomi: data["on_readings"],
        kunyomi: data["kun_readings"],
        name_readings: data["name_readings"],
        notes: data["notes"],
        heisig_en: data["heisig_en"],
        stroke_count: data["stroke_count"],
        grade: data["grade"],
        jlpt_level: data["jlpt"],
        freq_mainichi_shinbun: data["freq_mainichi_shinbun"],
        unicode: data["unicode"]
      ).find_or_create_by!(character: character)

      puts "✅"
    end

    puts "🎉 Done! Kanji imported."
  end
end
```
Now import files
```
rake import:kanji
```
## CORS

> CORS == Cross-origin resource sharing (CORS) A nice explanation can be found in this article. In summary:
> 
> CORS is an HTTP-header based security mechanism that defines who’s allowed to interact with your API. CORS is built into all modern web browsers, so in this case the “client” is a front-end of the application.
> 
> In the most simple scenario, CORS will block all requests from a different origin than your API. “Origin” in this case is the combination of protocol, domain, and port. If any of these three will be different between the front end and your Rails application, then CORS won’t allow the client to connect to the API.
> 
> So, for example, if your front end is running at https://example.com:443 and your Rails application is running at https://example.com:3000, then CORS will block the connections from the front end to the Rails API. CORS will do so even if they both run on the same server.

So the TL;DR is that we have to enable our front-end to access our back-end in 2 steps:
1. Uncomment gem "rack-cors" in the GEMFILE, then bundle install
2. Go to config/initializers/cors.rb and specify from which URL (and which actions) that you are willing to accept requests

For example:
```
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://example.com:80'
    resource '/orders',
      :headers => :any,
      :methods => [:post]
  end
end
```
Or to just blindly allow all (only for now)
```
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post, :patch, :put]
  end
end
```
## Adding a Front-End
Without knowing the endpoints or having our React app up and running, we have no way to interact with this app. So we can build a simple interface so that someone can play around with our API.
Generate the Controller
```
rails g controller pages home
```
Let's generate this controller (plus the view), but we need to be careful here on what it's creating. We need to update the routes and controller.

Update the Controller
You might notice that the new controller inheriting from ApplicationController which is inheriting from ActionController::API. It's using the API module because we created our app with the --api flag. This limits our app to only API functionality so we can change it back to the normal Rails flow. So, our controller should inherit from ActionController::Base
```
class PagesController < ActionController::Base
  def home
  end
end
```
Update Routes
The generator also created a route get "pages/home", which actually isn't useful to us at all. Let's go into our config/routes.rb file and change that to root to: pages#home instead.
Update the View
Since we used the --api flag when creating the app, we don't have the typical views/layouts/application.html.erb file anymore. Our app wasn't expecting any HTML views. So for our home.html.erb page, We'll have to add a full HTML setup. You can use the one in this tutorial as a starting point

## Heroku Deployment
Step 1: Create a Procfile for Heroku using to use web server
```
touch Procfile
```
```
web: bundle exec puma -C config/puma.rb 
```
Step 2: Update the database configuration for Heroku
config/database.yml
```
production:
  <<: *default
  url: <%= ENV['DATABASE_URL'] %>
```
Steo 3. Deploy to heroku
```
heroku create kanji-api --region=us
heroku addons:create heroku-postgresql:essential-0
git push heroku master
```
Step 4. Push Your Local DB to Heroku
Push your local DB
```
heroku pg:push kanji_api_development DATABASE_URL --app kanji-api
```
If you get an error like "Remote database is not empty", it means you previously ran rails db:migrate or the DB was already created. What you can do is Reset the Heroku database.
To fix that:
```
heroku pg:reset DATABASE_URL --app kanji-api
```
Then re-run:
```
heroku pg:push kanji_api_development DATABASE_URL --app kanji-api
```
🎉 Your database push to Heroku completed successfully.

## Install Pundit
Add gem
```
gem 'pundit'
```
Install gem
```
Bundle install
```
Install pundit
```
rails generate pundit:install
```

## Create User_Kanji policy
```
rails generate pundit:policy user_kanji
```
Add Associations
```
class UserKanjiPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end

  def show?
    user == record.user
  end

  def create?
    user.present?
  end

  def update?
    user == record.user
  end

  def destroy?
    user == record.user
  end
end
```

## Now we will create is a base_controller.rb
```
touch app/controllers/api/v1/base_controller.rb
```
Add Association
```
class Api::V1::BaseController < ActionController::API
  include Pundit

  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  rescue_from Pundit::NotAuthorizedError,   with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def user_not_authorized(exception)
    render json: {
      error: "Unauthorized #{exception.policy.class.to_s.underscore.camelize}.#{exception.query}"
    }, status: :unauthorized
  end

  def not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end
end
```
Next is to change some association for kanjis_controller.rb and user_kanjis_controller.rb
inherits Pundit + API logic from BaseController
```
class Api::V1::KanjisController < Api::V1::BaseController
class Api::V1::UserKanjisController < Api::V1::BaseController
```
Why do this? because we want both controllers to inherit from base_controller.rb using pundit + API-specific logic.

<img width="475" height="61" alt="Screenshot 2025-07-31 at 9 16 49 AM" src="https://github.com/user-attachments/assets/0597d2b3-6aed-4182-9eab-ca0ee7b9b2bb" />

## Setting up Authentication

Add association to app/controllers/api/v1/base_controller.rb
```
before_action :authenticate_user!
```
Add association to app/controllers/api/v1/user_kanjis_controller.rb
```
class Api::V1::UserKanjisController < Api::V1::BaseController
  def index
    @user_kanjis = policy_scope(UserKanji)
    render json: @user_kanjis
  end

  def show
    @user_kanji = UserKanji.find(params[:id])
    authorize @user_kanji
    render json: @user_kanji
  end

  def create
    @user_kanji = UserKanji.new(user_kanji_params)
    authorize @user_kanji
    if @user_kanji.save
      render json: @user_kanji
    else
      render json: { errors: @user_kanji.errors }, status: :unprocessable_entity
    end
  end

  def update?
    @user_kanji = UserKanji.find(find(params[:id]))
    authorize @user_kanji
    if @user_kanji.update(user_kanji_params)
      render json: @user_kanji
    else
      render json: { errors: @user_kanji.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @user_kanji = UserKanji.find(params[:id])
    authorize @user_kanji
    @user_kanji.destroy
    head :no_content
  end

  private

  def user_kanji_params
    params.require(:user_kanji).permit(:kanji_id)
  end
end
```
## Install Devise-JWT
Add gem
```
gem 'devise-jwt'
```
Install gem
```
bundle install
```
Generate JWT secret Key
```
rails secret
```
Add JWT secret to your credentials
```
rauks credentials:edit
```
add this line fo the file:
```
jwt_secret_key: [paste the secret key]
```
Generate Devise-JWT configuration
```
rails generate devise:install
```
if you can an error Type n and press Enter to not overwrite the file

Add JWT configuration at the end of the file in config/initializers/devise.rb
```
   config.jwt do |jwt|
     jwt.secret = Rails.application.credentials.jwt_secret_key
     jwt.dispatch_requests = [
       ['POST', %r{^/login$}]
     ]
     jwt.revocation_requests = [
       ['DELETE', %r{^/logout$}]
     ]
     jwt.expiration_time = 30.minutes.to_i
   end
```
