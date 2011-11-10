require 'date'

class WhenSun
  DEFAULT_ZENITH = 90.83333
  KNOWN_EVENTS = [:rise, :set]

  # Helper method: calculates sunrise, with the same parameters as calculate
  def self.rise(date, latitude, longitude, options = {})
    calculate(:rise, date, latitude, longitude, options)
  end

  # Helper method: calculates sunset, with the same parameters as calculate
  def self.set(date, latitude, longitude, options = {})
    calculate(:set, date, latitude, longitude, options)
  end

  # Calculates the sunrise or sunset time for a specific date and location
  #
  # ==== Parameters
  # * +event+ - One of :rise, :set.
  # * +date+ - An object that responds to yday.
  # * +latitude+ - The latitude of the location in degrees.
  # * +longitude+ - The longitude of the location in degrees.
  # * +options+ - Additional option is <tt>:zenith</tt>.
  #
  # ==== Example
  #   SunTimes.calculate(:rise, Date.new(2010, 3, 8), 43.779, 11.432)
  #   > Mon Mar 08 05:39:53 UTC 2010
  def self.calculate(event, date, latitude, longitude, options = {})
    raise "Unknown event '#{ event }'" unless KNOWN_EVENTS.include?(event)
    zenith = options.delete(:zenith) || DEFAULT_ZENITH

    # lngHour
    longitude_hour = longitude / 15.0

    # t
    base_time = event == :rise ? 6.0 : 18.0
    approximate_time = date.yday + (base_time - longitude_hour) / 24.0

    # M
    mean_sun_anomaly = (0.9856 * approximate_time) - 3.289

    # L
    sun_true_longitude = mean_sun_anomaly +
                        (1.916 * Math.sin(degrees_to_radians(mean_sun_anomaly))) +
                        (0.020 * Math.sin(2 * degrees_to_radians(mean_sun_anomaly))) +
                        282.634
    sun_true_longitude = coerce_degrees(sun_true_longitude)

    # RA
    tan_right_ascension = 0.91764 * Math.tan(degrees_to_radians(sun_true_longitude))
    sun_right_ascension = radians_to_degrees(Math.atan(tan_right_ascension))
    sun_right_ascension = coerce_degrees(sun_right_ascension)

    # right ascension value needs to be in the same quadrant as L
    sun_true_longitude_quadrant  = (sun_true_longitude  / 90.0).floor * 90.0
    sun_right_ascension_quadrant = (sun_right_ascension / 90.0).floor * 90.0
    sun_right_ascension += (sun_true_longitude_quadrant - sun_right_ascension_quadrant)

    # RA = RA / 15
    sun_right_ascension_hours = sun_right_ascension / 15.0

    sin_declination = 0.39782 * Math.sin(degrees_to_radians(sun_true_longitude))
    cos_declination = Math.cos(Math.asin(sin_declination))

    cos_local_hour_angle =
      (Math.cos(degrees_to_radians(zenith)) - (sin_declination * Math.sin(degrees_to_radians(latitude)))) /
                                 (cos_declination * Math.cos(degrees_to_radians(latitude)))

    # the sun never rises on this location (on the specified date)
    return nil if cos_local_hour_angle > 1
    # the sun never sets on this location (on the specified date)
    return nil if cos_local_hour_angle < -1

    # H
    suns_local_hour =
      if event == :rise
        360 - radians_to_degrees(Math.acos(cos_local_hour_angle))
      else
        radians_to_degrees(Math.acos(cos_local_hour_angle))
      end

    # H = H / 15
    suns_local_hour_hours = suns_local_hour / 15.0

    # T = H + RA - (0.06571 * t) - 6.622
    local_mean_time = suns_local_hour_hours + sun_right_ascension_hours - (0.06571 * approximate_time) - 6.622

    # UT = T - lngHour

    local_mean_time %= 24

    return (date.to_datetime() +(local_mean_time - longitude_hour)/24).to_time
  end

  private

  def self.degrees_to_radians(d)
    d.to_f / 360.0 * 2.0 * Math::PI
  end

  def self.radians_to_degrees(r)
    r.to_f * 360.0 / (2.0 * Math::PI)
  end

  def self.coerce_degrees(d)
    if d < 0
      d += 360
      return coerce_degrees(d)
    end
    if d >= 360
      d -= 360
      return coerce_degrees(d)
    end
    d
  end
end


#Backporting some date methods from Ruby 1.9
if RUBY_VERSION < '1.9'
  Date::HALF_DAYS_IN_DAY = Rational(1, 2) if RUBY_VERSION < '1.8.7'
  class Date
    def to_datetime()
      DateTime.new!(jd_to_ajd(jd, 0, 0), @of, @sg)
    end

    def jd_to_ajd(jd, fr, of=0)
      jd + fr - of - HALF_DAYS_IN_DAY
    end
  end

  class DateTime
    def to_time
      d = new_offset(0)
      d.instance_eval do
        Time.utc(year, mon, mday, hour, min, sec,
                 (sec_fraction * 86400000000).to_i)
      end.
          getlocal
    end
  end
end
