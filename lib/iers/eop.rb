# frozen_string_literal: true

module IERS
  module EOP
    # @attr polar_motion_x [Float] pole x-coordinate in arcseconds
    # @attr polar_motion_y [Float] pole y-coordinate in arcseconds
    # @attr ut1_utc [Float] UT1−UTC in seconds
    # @attr length_of_day [Float] excess LOD in seconds
    # @attr celestial_pole_x [Float] dX correction in milliarcseconds
    # @attr celestial_pole_y [Float] dY correction in milliarcseconds
    # @attr mjd [Float] Modified Julian Date of the query
    # @attr data_quality [Symbol] +:observed+ or +:predicted+
    Entry = ::Data.define(
      :polar_motion_x,
      :polar_motion_y,
      :ut1_utc,
      :length_of_day,
      :celestial_pole_x,
      :celestial_pole_y,
      :mjd,
      :data_quality
    ) do
      include HasDate
      include HasDataQuality
    end

    module_function

    # @param input [Time, Date, DateTime, nil]
    # @param jd [Float, nil] Julian Date
    # @param mjd [Float, nil] Modified Julian Date
    # @param interpolation [Symbol, nil] +:lagrange+ or +:linear+
    # @return [Entry]
    # @raise [OutOfRangeError]
    def at(input = nil, jd: nil, mjd: nil, interpolation: nil)
      query_mjd = TimeScale.to_mjd(input, jd: jd, mjd: mjd)
      interp = interpolation ? {interpolation: interpolation} : {}

      pm = PolarMotion.at(mjd: query_mjd, **interp)
      ut1 = UT1.at(mjd: query_mjd, **interp)
      cpo = CelestialPoleOffset.at(mjd: query_mjd, **interp)
      lod = LengthOfDay.at(mjd: query_mjd, **interp)

      quality = if [pm, ut1, cpo, lod].any?(&:predicted?)
        :predicted
      else
        :observed
      end

      Entry.new(
        polar_motion_x: pm.x,
        polar_motion_y: pm.y,
        ut1_utc: ut1.ut1_utc,
        length_of_day: lod.length_of_day,
        celestial_pole_x: cpo.x,
        celestial_pole_y: cpo.y,
        mjd: query_mjd,
        data_quality: quality
      )
    end

    # @param start_date [Date]
    # @param end_date [Date]
    # @return [Enumerator::Lazy<Entry>]
    def between(start_date, end_date)
      start_mjd = TimeScale.to_mjd(start_date)
      end_mjd = TimeScale.to_mjd(end_date)
      entries = Data.finals_entries

      EopLookup
        .range(entries, start_mjd, end_mjd)
        .lazy
        .map { |e| entry_from_parser(e) }
    end

    def entry_from_parser(e)
      Entry.new(
        polar_motion_x: e.bulletin_b_pm_x || e.pm_x,
        polar_motion_y: e.bulletin_b_pm_y || e.pm_y,
        ut1_utc: e.bulletin_b_ut1_utc || e.ut1_utc,
        length_of_day: e.lod / 1000.0,
        celestial_pole_x: e.dx,
        celestial_pole_y: e.dy,
        mjd: e.mjd,
        data_quality: derive_quality(e)
      )
    end

    def derive_quality(entry)
      flags = [
        entry.pm_flag,
        entry.ut1_flag,
        entry.nutation_flag
      ]
      if flags.include?("P")
        :predicted
      else
        :observed
      end
    end

    private_class_method :entry_from_parser, :derive_quality
  end
end
