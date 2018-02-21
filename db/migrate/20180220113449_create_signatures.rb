class CreateSignatures < ActiveRecord::Migration[5.0]
  def change
    create_table :signatures do |t|
      t.string :name
      t.text :labels

      t.timestamps
    end
  end
end
