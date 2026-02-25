# frozen_string_literal: true

module IERS
  module CelestialPoleOffset
    # @attr x [Float] dX correction in milliarcseconds
    # @attr y [Float] dY correction in milliarcseconds
    # @attr mjd [Float] Modified Julian Date of the query
    # @attr data_quality [Symbol] +:observed+ or +:predicted+
    Entry = ::Data.define(:x, :y, :mjd, :data_quality) do
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
