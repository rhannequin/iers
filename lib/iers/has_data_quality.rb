# frozen_string_literal: true

module IERS
  # @api private
  module HasDataQuality
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
