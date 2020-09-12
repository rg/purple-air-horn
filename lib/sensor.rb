# frozen_string_literal: true

class Sensor
  DATA_URL = 'https://www.purpleair.com/json?show='

  def initialize(sensor_id:)
    raise ArgumentError, "sensor_id must be specified" unless sensor_id.present?
    @sensor_id = sensor_id
  end

  def read(lrapa: true)
    fetch_raw_data

    old_value = load_saved || 0

    pm2_5 = stat(name: :pm2_5_atm)
    new_value = lrapa ? lrapa_conversion(pm2_5) : pm2_5
    save(value: new_value)

    {
      lrapa: lrapa,
      old_value: old_value,
      old_level: aqi_level_from_pm25(old_value),
      new_value: new_value,
      new_level: aqi_level_from_pm25(new_value),
      aqi_delta: (new_value - old_value).round(2),
      updated_at: last_updated
    }
  end

  private

  attr_reader :sensor_id, :data, :lrapa

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

  def lrapa_conversion(pm2_5_atm)
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

  def last_updated
    timestamp = stat(name: :LastSeen)
    Time.at(timestamp).strftime('%-m/%e %H:%M:%S')
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

  def save(value:)
    File.write("#{sensor_id}.data", value)
  end

  def load_saved
    File.read("#{sensor_id}.data").to_f
  rescue
    nil
  end
end
