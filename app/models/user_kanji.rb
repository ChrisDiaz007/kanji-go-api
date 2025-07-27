class UserKanji < ApplicationRecord
  belongs_to :user
  belongs_to :kanji
end
