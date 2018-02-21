json.array!(@signatures) do |signature|
  json.extract! signature, :id, :name, :labels
  json.url signature_url(signature, format: :json)
end
