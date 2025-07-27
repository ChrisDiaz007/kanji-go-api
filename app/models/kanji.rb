class Kanji < ApplicationRecord
  has_many :user_kanjis, dependent: :destroy
  has_many :users, through: :user_kanjis
end
