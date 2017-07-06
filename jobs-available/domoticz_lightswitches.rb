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

# Get's the current, featured xkcd entry
def get_favorite_lights
   lights = Hash.new

# TODO: improve URI handling...
   domoticz_uri = 'http://10.0.0.235:8080/json.htm?type=devices&filter=light&used=true&order=Name&favorite=1'
   favorite_lights = get_domoticz_json(domoticz_uri)["result"]

	favorite_lights.each do |favorite_light|
	  light = Hash.new
	  
	  light["label"] = favorite_light["Name"]
	  light["value"] = favorite_light["Status"]

	  if (favorite_light["Status"]).eql?('Off')
	    light["url"] = "http://10.0.0.235:8080/json.htm?type=command&param=switchlight&idx=#{ favorite_light["idx"] }&switchcmd=On"
	    light["isON"] = false
	  else
		light["url"] = "http://10.0.0.235:8080/json.htm?type=command&param=switchlight&idx=#{ favorite_light["idx"] }&switchcmd=Off"
		light["isON"] = true
	  end
	  
	  lights[favorite_light["idx"]] = light
	end

	return lights
end

#Basic logic:
SCHEDULER.every '60s', :first_in => 0 do |job|
	favorite_lights = get_favorite_lights
	
	#puts favorite_lights.values
	send_event('domoticz-lightswitches', { items: favorite_lights.values })
end
