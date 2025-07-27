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
Run Migrations
```
rails db:migrate
```

