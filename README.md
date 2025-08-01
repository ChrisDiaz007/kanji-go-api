## Creating a BackEnd Application with postgresql / devise-jwt authentication

<img width="1093" height="769" alt="Screenshot 2025-07-28 at 12 48 31 PM" src="https://github.com/user-attachments/assets/a13c7217-151d-47e5-b339-be3e3ae5b010" />


## Built With
- [Rails 7](https://guides.rubyonrails.org/) - Backend
- [PostgreSQL](https://www.postgresql.org/) - Database
- [Heroku](https://heroku.com/) - Deployment

## Getting Started
## Essentials Gems Being Used

> gem 'devise'
> 
> gem 'devise-jwt'
>
> gem 'jsonapi-serializer'
> 
> gem 'rack-cors'
>
> gem 'pundit'

## Create API App
```
rails new kanji-api --api -d postgresql
cd kanji-api
rails db:create

# Creates below 2 databases
# Created database 'kanji_api_development'
# Created database 'kanji_api_test'
```
## Create Github repository
```
gh repo create --public --source=.
```

## Notes
1. Check for below flag in config/application.rb
```
#config/application.rb
config.api_only = true
```
2. Check for postgres setup in config/database.yml
```
#config/database.yml
default: &default
  adapter: postgresql
  encoding: unicode
```
## configure rack-middleware for api only application
Update Gemfile to add/uncomment gem 'rack-cors'
And add the following contents to the config/initializers/cors.rb file.
```
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:3000'
    resource(
      '*',
      headers: :any,
      expose: ['access-token', 'expiry', 'token-type', 'Authorization'],
      methods: [:get, :patch, :put, :delete, :post, :options, :show]
    )
  end
end
```

## Install Devise using JWT Authentication
Add gem
```
gem 'devise'
gem `devise-jwt`
gem `gem 'jsonapi-serializer'

```
> devise’ and ‘devise-jwt’ for authentication and the dispatch and revocation of JWT tokens
> 
> jsonapi-serializer’ gem for formatting json responses.
Install gem
```
bundle install
```
Install devise
```
rails generate devise:install
```
For API only apps, navigation format should be emtpy
```
#config/initializers/devise.rb
config.navigational_formats = []
```

Generate User Model
```
rails generate devise User
# If you know wha information your User model will have you can just add it
# rails generate devise User first_name:string last_name:string
rails db:create db:migrate
```
Create devise Session and Registrations Controllers
```
rails g devise:controllers users -c sessions registrations
```
Update sessions_controller and registrations_controller
```
#app/controllers/users/sessions_controller.rb
class Users::SessionsController < Devise::SessionsController
  respond_to :json
end
```
```
#app/controllers/users/registrations_controller.rb
class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json
end
```
Add the routes aliases to override default routes provided by devise in the routes.rb
```
#config/routes.rb
Rails.application.routes.draw do
  devise_for :users, path: '', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    registration: 'signup'
  },
  controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }
end
```
Configure devise-jwt
```
#config/initializers/devise.rb
config.jwt do |jwt|
  jwt.secret = Rails.application.credentials.fetch(:secret_key_base)
  jwt.dispatch_requests = [
    ['POST', %r{^/login$}]
  ]
  jwt.revocation_requests = [
    ['DELETE', %r{^/logout$}]
  ]
  jwt.expiration_time = 30.minutes.to_i
end
```

> The jwt.expiration_time sets the expiration time for the generated token. In this example, it’s 30 minutes.

Set up a revocation strategy
```
rails g migration addJtiToUsers jti:string:index:unique
```
Update Migration
```
#db/migrate/xxxxxxxxx_add_jti_to_users.rb
def change
  add_column :users, :jti, :string, null: false
  add_index :users, :jti, unique: true
  # If you already have user records, you will need to initialize its `jti` column before setting it to not nullable. Your migration will look this way:
  # add_column :users, :jti, :string
  # User.all.each { |user| user.update_column(:jti, SecureRandom.uuid) }
  # change_column_null :users, :jti, false
  # add_index :users, :jti, unique: true
end
```
Update user.rb file to add revocation strategy
```
#app/models/user.rb
class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self
end
```
Run Migrations
```
rails db:migrate
```
Add respond_with using jsonapi_serializers method
```
rails generate serializer user id email created_at
```
Add the attributes
```
class UserSerializer
  include JSONAPI::Serializer
  attributes :id, :email, :created_at
end
```
Now, we have to tell devise to communicate through JSON by adding these methods in the RegistrationsController and SessionsController
```
class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json
  private
def respond_with(resource, _opts = {})
    if request.method == "POST" && resource.persisted?
      render json: {
        status: {code: 200, message: "Signed up sucessfully."},
        data: UserSerializer.new(resource).serializable_hash[:data][:attributes]
      }, status: :ok
    elsif request.method == "DELETE"
      render json: {
        status: { code: 200, message: "Account deleted successfully."}
      }, status: :ok
    else
      render json: {
        status: {code: 422, message: "User couldn't be created successfully. #{resource.errors.full_messages.to_sentence}"}
      }, status: :unprocessable_entity
    end
  end
end
```
```
class Users::SessionsController < Devise::SessionsController
  respond_to :json
  private
  def respond_with(resource, _opts = {})
    render json: {
      status: {code: 200, message: 'Logged in sucessfully.'},
      data: UserSerializer.new(resource).serializable_hash[:data][:attributes]
    }, status: :ok
  end
  def respond_to_on_destroy
    if current_user
      render json: {
        status: 200,
        message: "logged out successfully"
      }, status: :ok
    else
      render json: {
        status: 401,
        message: "Couldn't find an active session."
      }, status: :unauthorized
    end
  end
end
```
## Testing on Postman.
User Signup: Post http://localhost:3000/signup
```
{
  "user": {
    "email": "test@test.com",
    "password": "password"
  }
}
```
Response:
```
#response
{
  "status": {
    "code": 200,
    "message": "Signed up sucessfully."
  },
  "data": {
    "id": 1,
    "email": "test@test.com",
    "created_at": "2023-01-27T03:51:52.255Z",
    "created_date": "01/27/2023"
  }
}
```
User Login: Post http://localhost:3000/login
```
{
  "user": {
    "email": "test3@test.com",
    "password": "password"
  }
}
```
Response: 
```
#response
{
    "status": {
        "code": 200,
        "message": "Logged in sucessfully."
    },
    "data": {
        "id": 3,
        "email": "test2@test.com",
        "created_at": "02122024"
    }
}
```
User Logout: DELETE http://localhost:3000/logout
```
DELETE 'http://localhost:3000/logout' \
--header 'Authorization: Bearer xxxxxx'
```
Response:
```
#response
{
    "status": 200,
    "message": "logged out successfully"
}
```
Note: If you are getting an error that looked something like this:
```
Completed 500 Internal Server Error in 301ms 
```
```
ActionDispatch::Request::Session::DisabledSessionError (Your application has sessions disabled. To write to the session you must first configure a session store):
```
To implement the fix, create a new file in controllers/concerns:
```
# app/controllers/concerns/rack_session_fix.rb
module RackSessionFix
  extend ActiveSupport::Concern
  class FakeRackSession < Hash
    def enabled?
      false
    end
  end
  included do
    before_action :set_fake_rack_session_for_devise
    private
    def set_fake_rack_session_for_devise
      request.env['rack.session'] ||= FakeRackSession.new
    end
  end
end
```
```
class Users::SessionsController < Devise::SessionsController
  include RackSessionFix
  ...
end


class Users::RegistrationsController < Devise::RegistrationsController
  include RackSessionFix
  ...
end
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
Update Devise Configuration
Find the line that says config.navigational_formats and replace with
This tells Devise not to expect HTML responses since we're building an API.
```
config.navigational_formats = []
```
Create JWT Denylist Model
```
rails generate model jwt_denylist jti:string exp:datetime
```
Run migration
```
rails db:migrate
```
Update User Model
```
devise :database_authenticatable, :registerable,
            :recoverable, :rememberable, :validatable,
            :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist
```
Create API Registration Controller
```
touch app/controllers/api/v1/registrations_controller.rb
```
Add association
```
class Api::V1::RegistrationsController < Devise::RegistrationsController
 skip_before_action :verify_authenticity_token
 respond_to :json

 private

 def respond_with(resource, _opts = {})
   if resource.persisted?
     render json: {
       status: { code: 200, message: 'Signed up successfully.' },
       data: resource
     }
   else
     render json: {
       status: { message: "User couldn't be created successfully. #{resource.errors.full_messages.to_sentence}" }
     }, status: :unprocessable_entity
   end
 end
end
```
Update Routes
```
  devise_for :users, controllers: {
   registrations: 'api/v1/registrations',
   sessions: 'api/v1/sessions'
  }
```
