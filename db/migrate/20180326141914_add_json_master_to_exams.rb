class AddJsonMasterToExams < ActiveRecord::Migration[5.0]
  def change
    add_column :exams, :json_master, :string
  end
end
