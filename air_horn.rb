# TODO:
#  - Allow averaging of data from multiple sensors
#  - Improve handling of oscillations around threshold levels

require 'active_support/core_ext/string'
require 'awesome_print'
require 'faraday'
require 'json'
require 'pry-byebug'
require 'twilio-ruby'

require_relative 'lib/text_message'
require_relative 'lib/sensor'

data = Sensor.new(sensor_id: ENV['PURPLE_AIR_SENSOR_ID']).read

STDOUT.puts "."

unless data[:aqi_delta].zero?
  STDOUT.puts ">>> level: #{data[:new_level]}, new: #{data[:new_value]}, old: #{data[:old_value]}, updated at: #{data[:updated_at]}"

  if (data[:old_level] != data[:new_level])
    body = <<~MESSAGE
      Change in #{data[:lrapa] ? '(LRAPA) ' : ''}air quality!

      Level:  #{data[:new_level]}
      PM 2.5:  #{data[:new_value].round(2)} µg/m³
      Updated:  #{data[:updated_at]}
    MESSAGE

    STDOUT.puts "=====> Sending SMS"
    TextMessage.new.send(body: body)
  end
end
