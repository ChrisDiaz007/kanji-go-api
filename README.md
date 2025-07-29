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

## Add Associations
```
class Kanji < ApplicationRecord
  has_many :user_kanjis, dependent: :destroy
  has_many :users, through: :user_kanjis
end
```
```
class User < ApplicationRecord
  has_many :user_kanjis
  has_many :kanjis, through: :user_kanjis
end
```

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

## Add policy
```
rails generate pundit:policy user_kanji
```

## Rake from another API
Create /lib/tasks/import_kanji.rake
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
