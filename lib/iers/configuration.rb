# frozen_string_literal: true

module IERS
  class Configuration
    DEFAULT_CACHE_DIR = Pathname("~/.cache/iers").expand_path
    DEFAULT_SOURCES = {
      finals: "https://datacenter.iers.org/data/csv/finals2000A.all",
      leap_seconds: "https://hpiers.obspm.fr/iers/bul/bulc/Leap_Second.dat"
    }.freeze
    DEFAULT_DOWNLOAD_TIMEOUT = 30
    DEFAULT_INTERPOLATION = :lagrange
    DEFAULT_LAGRANGE_ORDER = 4
    INTERPOLATION_METHODS = %i[lagrange linear].freeze

    attr_reader :cache_dir,
      :sources,
      :download_timeout,
      :finals_path,
      :leap_second_path,
      :interpolation,
      :lagrange_order

    def initialize
      @cache_dir = DEFAULT_CACHE_DIR
      @sources = DEFAULT_SOURCES.dup
      @download_timeout = DEFAULT_DOWNLOAD_TIMEOUT
      @finals_path = nil
      @leap_second_path = nil
      @interpolation = DEFAULT_INTERPOLATION
      @lagrange_order = DEFAULT_LAGRANGE_ORDER
    end

    def cache_dir=(value)
      @cache_dir = Pathname(value)
    end

    def sources=(value)
      unless value.is_a?(Hash)
        raise ConfigurationError, "sources must be a Hash"
      end

      @sources = value
    end

    def download_timeout=(value)
      unless value.is_a?(Numeric) && value > 0
        raise ConfigurationError, "download_timeout must be positive"
      end

      @download_timeout = value
    end

    def finals_path=(value)
      @finals_path = value && Pathname(value)
    end

    def leap_second_path=(value)
      @leap_second_path = value && Pathname(value)
    end

    def interpolation=(value)
      unless INTERPOLATION_METHODS.include?(value)
        raise ConfigurationError,
          "interpolation must be one of: #{INTERPOLATION_METHODS.join(", ")}"
      end

      @interpolation = value
    end

    def lagrange_order=(value)
      unless value.is_a?(Integer) && value > 0 && value.even?
        raise ConfigurationError,
          "lagrange_order must be a positive even integer"
      end

      @lagrange_order = value
    end
  end
end
