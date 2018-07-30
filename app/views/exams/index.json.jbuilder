json.array!(@exams) do |exam|
  json.extract! exam, :id, :title, :description, :signature_id
  json.url exam_url(exam, format: :json)
end
