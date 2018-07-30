class AddJsonGraderToExams < ActiveRecord::Migration[5.0]
  def change
    add_column :exams, :json_grader, :string
  end
end
