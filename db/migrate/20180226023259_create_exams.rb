class CreateExams < ActiveRecord::Migration[5.0]
  def change
    create_table :exams do |t|
      t.string :title
      t.string :header
      t.text :description
      t.string :labels
      t.integer :amount
      t.text :students_list
      t.references :signature, foreign_key: true

      t.timestamps
    end
  end
end
