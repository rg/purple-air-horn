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
      old_level: aqi_level_from_pm2_5(old_value),
      new_value: new_value,
      new_level: aqi_level_from_pm2_5(new_value),
      aqi_delta: (new_value - old_value).round(2),
      updated_at: last_updated
    }
  end

  private

  attr_reader :sensor_id, :data

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

  # https://www.lrapa.org/DocumentCenter/View/4147/PurpleAir-Correction-Summary
  def lrapa_conversion(pm2_5_atm)
    calc = (0.5 * pm2_5_atm) - 0.66
    calc.round(3)
  end

  # https://forum.airnowtech.org/t/the-aqi-equation/169
  def aqi_level_from_pm2_5(pm2_5)
    c = pm2_5.round(1)

    if 0 <= c && c <= 12.0
      :good
    elsif 12.1 <= c && c <= 35.4
      :moderate
    elsif 35.5 <= c && c <= 55.4
      :unhealhy_sg
    elsif 55.5 <= c && c <= 150.4
      :unhealthy
    elsif 150.5 <= c && c <= 250.4
      :very_unhealthy
    elsif 250.5 <= c && c <= 500.4
      :hazardous
    elsif c <= 500.5
      :holy_shit
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

  def save(value)
    File.write("#{sensor_id}.data", value)
  end

  def load_saved
    File.read("#{sensor_id}.data").to_f
  rescue
    nil
  end
end
