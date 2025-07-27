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
  meanings:jsonb \
  onyomi:jsonb \
  kunyomi:jsonb \
  name_readings:jsonb \
  notes:jsonb \
  heisig_en:string \
  stroke_count:integer \
  grade:integer \
  jlpt_level:integer \
  freq_mainichi_shinbun:integer \
  unicode:string
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
