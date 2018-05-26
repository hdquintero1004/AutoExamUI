class AddRightToStatic < ActiveRecord::Migration[5.0]
  def change
    add_column :statics, :right, :integer
  end
end
