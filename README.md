geolocation_with_mongoid
========================

Simple demonstration on how to use mongoid 4.0.0.alpha1 with Rails 4.0

Today I tried to get familiar doing geolocation in Rails with [MongoDB](http://mongodb.org) through [Mongoid](http://mongoid.org).
To toughen up the task, I tried it with Rails 4.0 to which mongoid support is currently in beta.

#### Step 1:

We create a new app without ActiveRecord `rails new app_name --skip-active-record`

Open Gemfile and add:

	gem 'mongoid', '4.0.0.alpha1', github: 'mongoid/mongoid'

Now `bundle install` behold. 

#### Step 2:

With everything in place run `rails g mongoid:config`. If we have mongodb running locally we are ready to rumble.

#### Step 3:

We need something to locate:

	rails g scaffold Location from_position:Array to_position:Array

Why the array types? According to the [documentation](http://mongoid.org/en/mongoid/docs/indexing.html) (look for 'geospatial indexes') in order to get GIS data into mongodb we have to define Array fields in the document.

If we take a look into `app/views/location/_form.erb.html` you'll see:

	<div class="field">
		<%= f.label :from_position %><br>
		<%= f.text_field :from_position %>
	</div>
	<div class="field">
		<%= f.label :to_position %><br>
		<%= f.text_field :to_position %>
	</div>

That means, that somehow we would need to convert the textfield data into location array.

If we now start the app with `rails s` and go to `http://localhost:3000/locations` and try to create a new location record we'll see the following error:

	Mongoid::Errors::InvalidValue (
		Problem:
		  Value of type String cannot be written to a field of type Array
		Summary:
		  Tried to set a value of type String to a field of type Array
		Resolution:
		  Verify if the value to be set correspond to field definition):

or

{<1>}![error message in browser](/content/images/2014/Jan/Screen_Shot_2014_01_08_at_12_07_40_AM.png)

So we have to adjust the logic here. We would also would like to hide the location data, nobody want's to fill those out. Let's modify `location.rb`:

	class Location
		include Mongoid::Document

		field :from_position, type: Array, default: []
		field :to_position, type: Array, default: []

		attr_accessor :latitude, :longitude

		index({from_position: '2dsphere'}, background: true)
		index({to_position: '2dsphere'}, background: true)
        
		after_validation :transform_from_position
        private
        def transform_from_position
        	self.from_position = [longitude.to_f, latitude.to_f ]
        end
	end

What's happening here? 

	attr_accessor :latitude, :longitude

We add two temopral attributes to the model that we can use from the views but won't make it into the database.
We use the `:after_validation` callback to construct the neccessary array.
It is also wise to create indexes, hece:

		index({from_position: '2dsphere'}, background: true)
		index({to_position: '2dsphere'}, background: true)

then run:

	rake db:mongoid:create_indexes

#### Step 4:

We also have to adjust the views accordingly. Let's add two hidden fields

	<%= f.hidden_field :latitude %>
    <%= f.hidden_field :longitude %>
to `app/views/location/_from.html.erb` right before the `<div class="actions">`. And lets add the javascrip geolocation query to fill out the latitude and longitude hidden inputs when we create a new location.

	<script>
		var latitude;
        var longitude;
        if (navigator.geolocation) {
				navigator.geolocation.getCurrentPosition(function (position) {
            latitude = position.coords.latitude;
            longitude = position.coords.longitude;
			$("#location_latitude")[0].setAttribute("value", latitude);
			$("#location_longitude")[0].setAttribute("value", longitude);
		}, function (error) {
        	console.log(error);
		}, { enableHighAccuracy: true, timeout: Infinity, maximumAge: 2 * 60 * 1000 }
			);
		} else {
			alert('Geolocation is not supported in your browser');
		}
	</script>

This goes just after `<%= render 'form' %>` in `app/views/location/new.html.erb`.

The controller code `app/controllers/locations_controller.rb` needs to be updated as well to whitelist the the new attributes:

	params.require(:location).permit(:latitude, :longitude)
    
Start the app with `rails s`, open `http://localhost:3000/locations/new` in your browser, hit create location, and you're all set.

