class CreateSignaturesUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :signatures_users do |t|
      t.references :signature, foreign_key: true
      t.references :user, foreign_key: true
    end
  end
end
