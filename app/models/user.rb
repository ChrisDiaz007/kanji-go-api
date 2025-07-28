class User < ApplicationRecord
  has_many :user_kanjis
  has_many :kanjis, through: :user_kanjis
end
