class AddJsonMasterValidationToExams < ActiveRecord::Migration[5.0]
  def change
    add_column :exams, :json_master_validation, :string
  end
end
