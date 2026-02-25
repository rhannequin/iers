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
      # @return [Boolean]
      def observed?
        data_quality == :observed
      end

      # @return [Boolean]
      def predicted?
        data_quality == :predicted
      end
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
      ut1 = UT1.detailed_at(mjd: query_mjd, **interp)
      cpo = CelestialPoleOffset.at(mjd: query_mjd, **interp)
      lod = LengthOfDay.detailed_at(mjd: query_mjd, **interp)

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
  end
end
