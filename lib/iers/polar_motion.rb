# frozen_string_literal: true

module IERS
  module PolarMotion
    Entry = ::Data.define(:x, :y, :mjd, :data_quality) do
      def observed?
        data_quality == :observed
      end

      def predicted?
        data_quality == :predicted
      end
    end
  end
end
