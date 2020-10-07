# frozen_string_literal: true

class Sensor
  include Conversion

  DATA_URL = 'https://www.purpleair.com/json?show='

  def initialize(sensor_id:, conversion:)
    raise ArgumentError, 'sensor_id must be specified' unless sensor_id.present?

    @sensor_id = sensor_id
    @conversion = conversion
  end

  def read
    fetch_raw_data

    old_value = load_saved || 0

    if conversion_type == :us_epa
      pm2_5 = stat(name: :pm2_5_cf_1)
      humidity = stat(name: :humidity, sensor: 0)
    else
      pm2_5 = stat(name: :pm2_5_atm)
    end

    new_value = converted_value(pm2_5, humidity)
    save(new_value)

    {
      conversion: conversion_type,
      old_value: old_value,
      old_level: aqi_level_from_pm2_5(old_value),
      new_value: new_value,
      new_level: aqi_level_from_pm2_5(new_value),
      aqi_delta: (new_value - old_value).round(2),
      updated_at: last_updated
    }
  end

  private

  attr_reader :sensor_id, :conversion, :data

  def fetch_raw_data
    response = Faraday.get("#{DATA_URL}#{sensor_id}")
    @data = JSON.parse(response.body, symbolize_names: true)
  end

  def stat(name:, sensor: nil)
    stats0 = data[:results][0]
    stats1 = data[:results][1]

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

  def last_updated
    timestamp = stat(name: :LastSeen)
    Time.at(timestamp).strftime('%-m/%-e %H:%M:%S')
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

  def save(value)
    File.write("#{sensor_id}.data", value)
  end

  def load_saved
    File.read("#{sensor_id}.data").to_f
  rescue
    nil
  end
end
