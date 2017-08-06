##################
#
# This widget uses data from openov.nl to show depatrures for {bus|tram|train}stops
#
# See: https://github.com/skywave/KV78Turbo-OVAPI/wiki
#


require 'net/http'
require 'json'
require 'date'

# URL endpoint for REST API of Timingpoint (https://github.com/skywave/KV78Turbo-OVAPI/wiki/TimingPointCode)
OVINFO_API_URL = "http://v0.ovapi.nl"

# This hash idendifies te stops to include.
# We assume a general stop name, with a sub-hash that has a direction and a Timingpointcode 
STOPIDS = [50200600,50200590,50200900,50200911]


# Get the json data from domoticz server
def get_ov_json(ov_uri)
   uri = URI(ov_uri)
   response = Net::HTTP.get(uri)
   json_response = JSON.parse(response)
end

# Create URI, pull data and return results
def get_tpc_data(base_uri, stopids)
	timepointcode_uri = "#{base_uri}/tpc/#{stopids.join(",")}"
   	
   	puts timepointcode_uri
	return get_ov_json(timepointcode_uri) 
end

tpc_data_points = get_tpc_data(OVINFO_API_URL, STOPIDS)
haltes = STOPIDS

tpc_data_points.each do |tpc_data_point|
  puts tpc_data_point[50200600]["Stop"]
  #puts tpc_data_point["Stop"]["TimingPointName"]
  #puts tpc_data_point["Stop"]["TimingPointCode"]
  puts "=========================================="
  
  #label = (usage_data_point["d"].split " ")[1]
  #value = usage_data_point["v"]
  #usage[label] = value
end




# Handle timeranges to make more pretty graphs as domoticz does not ship time points for empty data
def mk_timerange(range, start)
	hours = ["00:00", "01:00", "02:00", "03:00", "04:00", "05:00", "06:00", "07:00", "08:00", "09:00", "10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00", "17:00", "18:00", "19:00", "20:00", "21:00", "22:00", "23:00"]
	months = [1..12]
	days = []

	case range
	when "week"
		#return "week"
	when "month"
		#return "month"
	when "day"
		# assume hours and make sure we start at the right time
		startpos = hours.index(start)
		
		if (startpos > 0) then
			a1 = hours[startpos..hours.length-1]
			a2 = hours[0..startpos-1]

			return (a1 + a2).flatten
		else
			return hours
		end
	end
end	
	

# Run a get usages function to get the data and put it into arrays
def get_usage(range, idx)
   usage =  Hash.new
   usage["labels"] = []
   usage["values"] = []

   graph_data =  Hash.new
   graph_data["labels"] = []
   graph_data["values"] = []

   usage_data = get_usage_data(idx, range)
	
	
   case range
  
   when "day"
     first_data_point = (usage_data[0]["d"].split " ")[1]
 
     # create a time series
     series = mk_timerange(range, first_data_point)
     
     # read data from Json and put into hash
     usage_data.each do |usage_data_point|
	   label = (usage_data_point["d"].split " ")[1]
       value = usage_data_point["v"]
       usage[label] = value
	 end

     # loop over series and fill graphdata from usage hash
     series.each do |series_data_point|
       graph_data["labels"].push series_data_point
       graph_data["values"].push usage[series_data_point]
     end

   else
     # read data from Json and put into hash
     usage_data.each do |usage_data_point|
       graph_data["labels"].push usage_data_point["d"]
       graph_data["values"].push usage_data_point["v"]
     end
   end
     
   return graph_data
end


#SCHEDULER.every '60s', :first_in => 0 do |job|

#    get_ov_json(OVINFO_API_URL)

#	gas_usage = get_usage("day", 38)
	
#	puts gas_usage["labels"]
#	puts gas_usage["values"]
	
#	labels = gas_usage["labels"]
#   data = [
#      {
 #       label: 'Gas verbruik (m3)',
  #      data: gas_usage["values"],
   #     backgroundColor: [ 'rgba(255, 99, 132, 0.2)' ] * labels.length,
    #    borderColor: [ 'rgba(255, 99, 132, 1)' ] * labels.length,
     #   borderWidth: 1,
      #}
    #]

   #send_event('domoticz-p1-gasusage', { labels: labels, datasets: data })
#end
