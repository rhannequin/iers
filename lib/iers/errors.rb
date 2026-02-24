# frozen_string_literal: true

module IERS
  class Error < StandardError; end

  class DataError < Error; end

  class ParseError < DataError
    attr_reader :path, :line_number

    def initialize(message = nil, path: nil, line_number: nil)
      @path = path
      @line_number = line_number
      super(message)
    end
  end

  class FileNotFoundError < DataError
    attr_reader :path

    def initialize(message = nil, path: nil)
      @path = path
      super(message)
    end
  end

  class DownloadError < Error; end

  class NetworkError < DownloadError
    attr_reader :url, :status_code

    def initialize(message = nil, url: nil, status_code: nil)
      @url = url
      @status_code = status_code
      super(message)
    end
  end

  class ValidationError < DownloadError
    attr_reader :path, :reason

    def initialize(message = nil, path: nil, reason: nil)
      @path = path
      @reason = reason
      super(message)
    end
  end

  class ConfigurationError < Error; end

  class OutOfRangeError < Error
    attr_reader :requested_mjd, :available_range

    def initialize(message = nil, requested_mjd: nil, available_range: nil)
      @requested_mjd = requested_mjd
      @available_range = available_range
      super(message)
    end
  end
end
