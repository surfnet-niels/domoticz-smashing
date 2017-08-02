###########################
#
# Adopted from https://github.com/marceldegraaf/dashing-ns
#
########################### 

# Handle config centrally
require 'yaml'
cnf = YAML::load_file(File.join(__dir__, '../config.yml'))

DEBUG_ON = cnf['debug_on']
# See http://www.ns.nl/reisinformatie/ns-api for information on registering aapi username and password
NS_API_USERNAME = cnf['ns']['ns_api_username']
NS_API_PASSWORD = cnf['ns']['ns_api_password']
# This is an example class that interacts with the NS API.
# In this case we've set the DEPART_FROM constant.
# Use the user friendly display names from the station list as provided by the NS api: http://www.ns.nl/reisinformatie/ns-api/documentatie-stationslijst.html
DEPART_FROM = cnf['ns']['depart_from']
DESTINATION = cnf['ns']['destination']

require 'ns' # <= make sure the "ns-api" gem is in your Gemfile

# This class was originally in seperate lib file but included here for simplicity
class Train
  def initialize
    Ns.configure do |config|
      config.username = NS_API_USERNAME
      config.password = NS_API_PASSWORD
    end
  end

  def trip(destination, options = {})
    trip_options = { from: DEPART_FROM, to: destination, departure: Time.now + (20*60) }
    trip = Ns::Trip.new(trip_options.merge(options))
    
    puts trip if DEBUG_ON
    
    travel_option = trip.travel_options.select { |to| to.optimal == true }.first

    {
      destination: destination,
      platform:    travel_option.platform,
      departure:   travel_option.planned_departure.strftime("%H:%M"),
      delay:       travel_option.delay / 60,
      delayed:     (travel_option.delay > 0 ? 'delayed' : 'not-delayed')
    }
  end

  def status
    disruptions? ? 'disruptions' : 'ok'
  end

  def status_text
    disruptions? ? "disruptions at #{DEPART_FROM}" : "no disruptions at #{DEPART_FROM}"
  end

  private

  def disruption_collection
    @disruption_collection ||= Ns::DisruptionCollection.new(station: DEPART_FROM, actual: true, include_planned: false)
  end

  def disruptions?
    disruption_collection.unplanned_disruptions.any?
  end

end


@train = Train.new

SCHEDULER.every('10m', allow_overlapping: false, first_in: '1s') do
  trips = [
    @train.trip(DESTINATION)
  ]

  trips = trips.sort { |a,b| a[:departure] <=> b[:departure] }

  disruptions = @train.status_text
  status = @train.status

  puts trips if DEBUG_ON
  puts disruptions if DEBUG_ON
  puts status if DEBUG_ON

  send_event("ns", { items: trips, disruptions: disruptions, status: status })
end

