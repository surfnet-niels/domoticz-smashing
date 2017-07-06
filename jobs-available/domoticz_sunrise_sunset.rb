# This job queries the domoticz API for the sunrise and sunset, processes teh data and feeds that into the extended-clock widget

require 'net/http'
require 'json'

## values include: type=devices&filter=light&used=true&order=Name&favorite=1
## See: https://www.domoticz.com/wiki/Domoticz_API/JSON_URL's

#DOMOTICZ_URI = 'http://10.0.0.235:8080/json.htm'



# Get the json data from domoticz server
# pass filtes to specify URL
def get_domoticz_json(domoticz_uri)
   uri = URI(domoticz_uri)
   response = Net::HTTP.get(uri)
   JSON.parse(response)
end

def get_sunrise_sunset
   sun = Hash.new

# TODO: improve URI handling...
   domoticz_uri = 'http://10.0.0.235:8080/json.htm?type=command&param=getSunRiseSet'
   sun["rise"] = get_domoticz_json(domoticz_uri)["Sunrise"]
   sun["set"] = get_domoticz_json(domoticz_uri)["Sunset"]

   return sun
end

#Basic logic:
SCHEDULER.every '60s', :first_in => 0 do |job|
	sunrise_sunset = get_sunrise_sunset
	
	#puts sunrise_sunset["rise"]
	#puts sunrise_sunset["set"]
	send_event('extended_clock-sunrise_sunset', { sunrise: "\u21D1 " + sunrise_sunset["rise"], sunset: "\u21D3 " + sunrise_sunset["set"] })
end
