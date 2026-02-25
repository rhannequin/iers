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
  end
end
