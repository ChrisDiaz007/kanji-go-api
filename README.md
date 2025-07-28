## Kanji go API

## Built With
- [Rails 7](https://guides.rubyonrails.org/) - Backend / Front-end
- [PostgreSQL](https://www.postgresql.org/) - Database
- [Heroku](https://heroku.com/) - Deployment

## Getting Started
### Setup

## Create App
```
rails new kanji-go-api --api -d postgresql
```
## Create Github repository
```
gh repo create --public --source=.
```

## Designing the DB


## Creating the Model
```
rails db:create
```

## Gems Used
```
gem 'devise'
gem 'pundit'
gem 'jwt'
gem 'rack-cors'
```

## Install gems
```
bundle install
```

## Install Devise
```
rails generate devise:install
```

## Create User Model
```
rails generate model User first_name:string last_name:string
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
## Update Model for using array
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

## Install Pundit
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
