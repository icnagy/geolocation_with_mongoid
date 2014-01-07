class Location
  include Mongoid::Document
  field :from_position, type: Array
  field :to_position, type: Array

  attr_accessor :latitude, :longitude

  index({from_position: '2dsphere'}, background: true)
  index({to_position: '2dsphere'}, background: true)

end
