# frozen_string_literal: true

require_relative "iers/version"
require_relative "iers/errors"
require_relative "iers/configuration"

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
