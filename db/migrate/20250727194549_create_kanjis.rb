class CreateKanjis < ActiveRecord::Migration[7.1]
  def change
    create_table :kanjis do |t|
      t.string :character
      t.string :meanings, array: true, default: []
      t.string :onyomi, array: true, default: []
      t.string :kunyomi, array: true, default: []
      t.string :name_readings, array: true, default: []
      t.string :notes, array: true, default: []
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
