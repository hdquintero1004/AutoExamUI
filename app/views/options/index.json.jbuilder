json.array!(@options) do |option|
  json.extract! option, :id, :body, :true_or_false, :question_id
  json.url option_url(option, format: :json)
end
