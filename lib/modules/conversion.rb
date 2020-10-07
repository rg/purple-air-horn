# frozen_string_literal: true

module Conversion
  def conversion_type
    return :raw unless conversion.present?

    conversion.tr(' ', '_').downcase.to_sym
  end

  def converted_value(pm2_5, humidity)
    case conversion_type
      when :us_epa
        us_epa_conversion(pm2_5, humidity)
      when :aqandu
        aqandu_conversion(pm2_5)
      when :lrapa
        lrapa_conversion(pm2_5)
      when :raw
        pm2_5
    end
  end

  # https://cfpub.epa.gov/si/si_public_record_report.cfm?dirEntryId=349513&Lab=CEMM&simplesearch=0&showcriteria=2&sortby=pubDate&timstype=&datebeginpublishedpresented=08/25/2018
  def us_epa_conversion(pm2_5_cf_1, rh)
    calc = (0.534 * pm2_5_cf_1) - (0.0844 * rh) + 5.604
    calc.round(3)
  end

  # http://www.aqandu.org/airu_sensor#calibrationSection
  def aqandu_conversion(pm2_5_atm)
    calc = (0.778 * pm2_5_atm) + 2.65
    calc.round(3)
  end

  # https://www.lrapa.org/DocumentCenter/View/4147/PurpleAir-Correction-Summary
  def lrapa_conversion(pm2_5_atm)
    calc = (0.5 * pm2_5_atm) - 0.66
    return 0 if calc.negative?

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
    elsif 500.5 <= c
      :holy_shit
    end
  end
end
