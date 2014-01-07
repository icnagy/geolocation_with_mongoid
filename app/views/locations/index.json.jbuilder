json.array!(@locations) do |location|
  json.extract! location, :id, :from_position, :to_position
  json.url location_url(location, format: :json)
end
