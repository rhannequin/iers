# frozen_string_literal: true

module IERS
  module LengthOfDay
    # @attr length_of_day [Float] excess LOD in seconds
    # @attr mjd [Float] Modified Julian Date of the query
    # @attr data_quality [Symbol] +:observed+ or +:predicted+
    Entry = ::Data.define(:length_of_day, :mjd, :data_quality) do
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
