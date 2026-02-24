# frozen_string_literal: true

require_relative "iers/version"
require_relative "iers/errors"
require_relative "iers/configuration"
require_relative "iers/update_result"
require_relative "iers/data_status"
require_relative "iers/downloader"
require_relative "iers/data"

module IERS
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end

    def reset_configuration!
      @configuration = nil
    end
  end
end
