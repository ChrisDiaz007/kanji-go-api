class CreateKanjis < ActiveRecord::Migration[7.1]
  def change
    create_table :kanjis do |t|
      t.string :character
      t.jsonb :meanings
      t.jsonb :onyomi
      t.jsonb :kunyomi
      t.jsonb :name_readings
      t.jsonb :notes
      t.string :heisig_en
      t.integer :stroke_count
      t.integer :grade
      t.integer :jlpt_level
      t.integer :freq_mainichi_shinbun
      t.string :unicode

      t.timestamps
    end
  end
end
