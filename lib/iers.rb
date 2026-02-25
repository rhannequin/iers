# frozen_string_literal: true

require_relative "iers/version"
require_relative "iers/errors"
require_relative "iers/configuration"
require_relative "iers/update_result"
require_relative "iers/data_status"
require_relative "iers/downloader"
require_relative "iers/parsers"
require_relative "iers/data"
require_relative "iers/time_scale"
require_relative "iers/has_date"
require_relative "iers/has_data_quality"
require_relative "iers/interpolation"
require_relative "iers/eop_lookup"
require_relative "iers/leap_second"
require_relative "iers/ut1"
require_relative "iers/polar_motion"
require_relative "iers/celestial_pole_offset"
require_relative "iers/length_of_day"
require_relative "iers/delta_t"
require_relative "iers/eop"

module IERS
  class << self
    # @return [Configuration]
    def configuration
      @configuration ||= Configuration.new
    end

    # @yield [Configuration]
    # @return [void]
    def configure
      yield configuration
    end

    # @return [void]
    def reset_configuration!
      @configuration = nil
      Data.clear_loaded!
    end

    # @return [void]
    def reset!
      reset_configuration!
    end
  end
end
