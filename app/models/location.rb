class Location
  include Mongoid::Document
  field :from_position, type: Array
  field :to_position, type: Array

  attr_accessor :latitude, :longitude

  index({from_position: '2dsphere'}, background: true)
  index({to_position: '2dsphere'}, background: true)
  after_validation :transform_from_position
  
  private

  def transform_from_position
    self.from_position = [longitude.to_f, latitude.to_f ]
  end
end
