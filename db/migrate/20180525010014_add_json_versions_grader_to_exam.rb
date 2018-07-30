class AddJsonVersionsGraderToExam < ActiveRecord::Migration[5.0]
  def change
    add_column :exams, :json_versions_grader, :string
  end
end
