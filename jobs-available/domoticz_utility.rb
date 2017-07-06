require 'net/http'
require 'json'

points = []


# Get and parse the json data from domoticz server
# pass filters to specify URL
def get_domoticz_json(domoticz_uri)
   uri = URI(domoticz_uri)
   response = Net::HTTP.get(uri)
   return JSON.parse(response)
end

# Read and parse the json data from local filesystem
def read_domoticz_json(domoticz_jsonfile)
   file = File.read(domoticz_jsonfile)
   return JSON.parse(file)
end

# Get's the current, featured xkcd entry
def get_utility_data


   datapoints = []

# TODO: improve URI handling...
   domoticzFile = "/home/niels/dev/my-project/domoticz_data/38_day.json"
   utilityData = read_domoticz_json(domoticzFile)["result"]

# 2017-03-18 14:00



	utilityData.each do |utilValues|
	
      #puts utilValues["d"].split(" ")[1].split(":")[0] 
	
	  datapoints << { x: utilValues["d"].split(" ")[1].split(":")[0], y: utilValues["v"] }
	end

	return datapoints
end

# Populate the graph with some random points
#points = []
#(1..10).each do |i|
# points << { x: i, y: rand(50) }
#end
#last_x = points.last[:x]


SCHEDULER.every '2s' do
  #points.shift
  #last_x += 1
  #points << { x: last_x, y: rand(50) }

  points = get_utility_data

  send_event('domoticz-utility', points: points)
end
