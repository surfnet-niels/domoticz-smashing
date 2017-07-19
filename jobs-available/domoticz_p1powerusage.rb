require 'net/http'
require 'json'
require 'date'

## See: https://www.domoticz.com/wiki/Domoticz_API/JSON_URL's

# Define device base URI
# Shoudl be pulled from config at some point
def get_domoticz_base_uri
   return "http://10.0.0.235:8080/json.htm"
end


# Get the json data from domoticz server
def get_domoticz_json(domoticz_uri)
   uri = URI(domoticz_uri)
   response = Net::HTTP.get(uri)
   JSON.parse(response)
end

# Create URI, pull data and return results
def get_usage_data(idx, range)
	domoticz_base_uri = get_domoticz_base_uri
   	domoticz_uri = "#{domoticz_base_uri}?type=graph&sensor=counter&idx=#{idx}&range=#{range}"
   	   	
   	puts domoticz_uri
	return get_domoticz_json(domoticz_uri)["result"]
   
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
       graph_data["u1_values"].push usage_data_point["v"]
       graph_data["u2_values"].push usage_data_point["v2"]
       graph_data["r1_values"].push usage_data_point["r1"]
       graph_data["r2_values"].push usage_data_point["r2"]
     end
   end
     
   return graph_data
end


SCHEDULER.every '60s', :first_in => 0 do |job|
	power_usage = get_usage("day", 37)
	
	puts power_usage["labels"]
	puts power_usage["u1_values"]
    puts power_usage["u2_values"]
    puts power_usage["r1_values"]
    puts power_usage["r2_values"]
	
	labels = power_usage["labels"]
    data = [
      {
        label: 'Stroom verbruik hoog (kWh)',
        data: power_usage["u1_values"],
        backgroundColor: [ 'rgba(255, 99, 132, 0.2)' ] * labels.length,
        borderColor: [ 'rgba(255, 99, 132, 1)' ] * labels.length,
        borderWidth: 1,
      }, {
        label: 'Stroom verbruik laag (kWh)',
        data: power_usage["u2_values"],
        backgroundColor: [ 'rgba(255, 173, 86, 0.2)' ] * labels.length,
        borderColor: [ 'rgba(255, 173, 86, 1)' ] * labels.length,
        borderWidth: 1,
      }, {
        label: 'Stroom levering hoog (kWh)',
        data: power_usage["r1_values"],
        backgroundColor: [ 'rgba(44, 67, 153, 0.2)' ] * labels.length,
        borderColor: [ 'rgba(44, 67, 153, 1)' ] * labels.length,
        borderWidth: 1,
      }, {
        label: 'Stroom levering laag (kWh)',
        data: power_usage["r2_values"],
        backgroundColor: [ 'rgba(99, 124, 216, 0.2)' ] * labels.length,
        borderColor: [ 'rgba(99, 124, 216, 1)' ] * labels.length,
        borderWidth: 1,
      }
    ]

   send_event('domoticz-p1-powerusage', { labels: labels, datasets: data })
end
