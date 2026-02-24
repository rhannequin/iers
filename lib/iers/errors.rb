# frozen_string_literal: true

module IERS
  class Error < StandardError; end

  class DataError < Error; end

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
end
