# TODO:
#  - Allow averaging of data from multiple sensors
#  - Improve handling of oscillations around threshold levels

require 'active_support/core_ext/string'
require 'awesome_print'
require 'faraday'
require 'json'
require 'pry-byebug'
require 'twilio-ruby'

require_relative 'text_message'

class SensorData
  DATA_URL = 'https://www.purpleair.com/json?show='

  def initialize(sensor_id:)
    @sensor_id = sensor_id
    response = Faraday.get("#{DATA_URL}#{sensor_id}")
    @data = JSON.parse(response.body, symbolize_names: true)
  end

  def report
    old_value = read || 0
    new_value = convert_to_lrapa(stat(name: :pm2_5_atm))
    delta = (new_value - old_value).round(2)

    old_aqi = aqi_level_from_pm25(old_value)
    new_aqi = aqi_level_from_pm25(new_value)

    STDOUT.puts "."
    unless delta.zero?
      write(value: new_value)

      STDOUT.puts ">>> level: #{new_aqi}, new: #{new_value}, old: #{old_value}, updated at: #{last_updated}"

      if (old_aqi != new_aqi)
        STDOUT.puts "=====> Sending SMS"
        TextMessage.new.send(
          body: "Change in (LRAPA) air quality!\n\nLevel:  #{new_aqi}\nPM 2.5:  #{new_value.round(2)} µg/m³\nUpdated:  #{last_updated}"
        )
      end
    end
  end

  private

  def stat(name:, sensor: nil)
    stats0 = @data[:results][0]
    stats1 = @data[:results][1]

    value0 = parse_value(stats0[name])
    value1 = parse_value(stats1[name])

    unless [value0, value1].detect { |v| v.is_a?(Numeric) }
      return value0
    end

    value =
      case sensor
        when 0
          value0
        when 1
          value1
        else
          ((value0 + value1) / 2)
      end

    value.round(3)
  end

  def convert_to_lrapa(pm2_5_atm)
    calc = (0.5 * pm2_5_atm) - 0.66
    calc.round(3)
  end

  def aqi_level_from_pm25(val)
    if 0 <= val && val <= 12
      :good
    elsif 12 < val && val <= 35
      :moderate
    elsif 35 < val && val <= 55
      :unhealhy_sg
    elsif 55 < val && val <= 150
      :unhealthy
    elsif 150 < val && val <= 250
      :very_unhealthy
    elsif 250 < val
      :hazardous
    end
  end

  def parse_value(value)
    return value unless numeric?(value)
    value.is_a?(Integer) ? value.to_i : value.to_f
  end

  def numeric?(value)
    Float(value) != nil
  rescue
    false
  end

  def last_updated
    timestamp = stat(name: :LastSeen)
    Time.at(timestamp).strftime('%-m/%e %H:%M:%S')
  end

  def write(value:)
    File.write("#{@sensor_id}.data", value)
  end

  def read
    File.read("#{@sensor_id}.data").to_f
  rescue
    nil
  end
end

raise ArgumentError, "PURPLE_AIR_SENSOR_ID must be set" unless (sensor_id = ENV['PURPLE_AIR_SENSOR_ID']).present?
SensorData.new(sensor_id: ENV['PURPLE_AIR_SENSOR_ID']).report
