class CreateUserKanjis < ActiveRecord::Migration[7.1]
  def change
    create_table :user_kanjis do |t|
      t.references :user, null: false, foreign_key: true
      t.references :kanji, null: false, foreign_key: true
      t.datetime :last_reviewed_at

      t.timestamps
    end
  end
end
