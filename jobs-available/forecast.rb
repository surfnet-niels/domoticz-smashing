require 'net/http'
require 'json'

# Forecast API Key from https://developer.forecast.io
forecast_api_key = "a81e54d7b760febab402c281b860c4c5"

# Latitude, Longitude for location
forecast_location_lat = "52.090601"
forecast_location_long = "5.233253"

# Unit Format
# "us" - U.S. Imperial
# "si" - International System of Units
# "uk" - SI w. windSpeed in mph
forecast_units = "si"

# Language for display
# See darknet API reference for values
forecast_language = "nl"
  
SCHEDULER.every '10m', :first_in => 0 do |job|
  http = Net::HTTP.new("api.darksky.net", 443)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  response = http.request(Net::HTTP::Get.new("/forecast/#{forecast_api_key}/#{forecast_location_lat},#{forecast_location_long}?units=#{forecast_units}&lang=#{forecast_language}"))
  forecast = JSON.parse(response.body)  
  forecast_current_temp = forecast["currently"]["temperature"].round
  forecast_tomorrow_temp = forecast["daily"]["data"][0]["temperatureMax"].round
  forecast_hour_summary = forecast["hourly"]["summary"]
  send_event('forecast', { current_temperature: "#{forecast_current_temp}&deg;", tomorrow_temperature: "#{forecast_tomorrow_temp}&deg;", hour_forecast: "#{forecast_hour_summary}"})
end

