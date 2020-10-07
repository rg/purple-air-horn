# TODO:
#  - Allow averaging of data from multiple sensors

require 'active_support/core_ext/string'
require 'awesome_print'
require 'faraday'
require 'json'
require 'pry-byebug'
require 'twilio-ruby'

require_relative 'lib/modules/conversion'
require_relative 'lib/sensor'
require_relative 'lib/text_message'

conversion = ENV['CONVERSION']
data = Sensor.new(
        sensor_id: ENV['PURPLE_AIR_SENSOR_ID'],
        conversion: conversion
      ).read

STDOUT.puts "."

unless data[:aqi_delta].zero?
  STDOUT.puts ">>> level: #{data[:new_level]}, new: #{data[:new_value]}, old: #{data[:old_value]}, updated at: #{data[:updated_at]}"

  if (data[:old_level] != data[:new_level])
    body = <<~MESSAGE
      Change in air quality!

      Level:  #{data[:new_level]}
      PM 2.5:  #{data[:new_value].round(2)} µg/m³ #{conversion.present? ? "(#{conversion})" : ''}
      Updated:  #{data[:updated_at]}
    MESSAGE

    STDOUT.puts "=====> Sending SMS"
    TextMessage.new.send(body: body)
  end
end
