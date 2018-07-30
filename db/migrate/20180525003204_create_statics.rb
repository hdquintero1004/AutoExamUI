class CreateStatics < ActiveRecord::Migration[5.0]
  def change
    create_table :statics do |t|
      t.references :exam, foreign_key: true
      t.integer :exam_version
      t.integer :document_id
      t.integer :question_id
      t.string :answer
      t.integer :note

      t.timestamps
    end
  end
end
