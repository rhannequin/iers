# frozen_string_literal: true

require "net/http"
require "uri"
require "tempfile"

module IERS
  class Downloader
    MAX_REDIRECTS = 5

    def initialize(timeout:)
      @timeout = timeout
    end

    def fetch(url, dest_path)
      dest_path = Pathname(dest_path)
      dest_path.dirname.mkpath

      body = http_get(url)
      validate!(body, dest_path)
      atomic_write(dest_path, body)
    end

    private

    def http_get(url, redirect_count = 0)
      if redirect_count > MAX_REDIRECTS
        raise NetworkError.new(
          "Too many redirects",
          url: url,
          status_code: nil
        )
      end

      uri = URI.parse(url)
      response = perform_request(uri)

      case response
      when Net::HTTPRedirection
        location = response["Location"]
        resolved = uri + location
        http_get(resolved.to_s, redirect_count + 1)
      when Net::HTTPSuccess
        response.body
      else
        raise NetworkError.new(
          "HTTP #{response.code}: #{response.message}",
          url: url,
          status_code: response.code.to_i
        )
      end
    rescue SocketError,
      Errno::ECONNRESET,
      Errno::ECONNREFUSED,
      Net::OpenTimeout,
      Net::ReadTimeout => e
      raise NetworkError.new(e.message, url: url, status_code: nil)
    end

    def perform_request(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = @timeout
      http.read_timeout = @timeout
      http.get(uri.request_uri)
    end

    def validate!(body, dest_path)
      return unless body.nil? || body.empty?

      raise ValidationError.new(
        "Downloaded file is empty",
        path: dest_path.to_s,
        reason: "empty response body"
      )
    end

    def atomic_write(dest_path, body)
      tempfile = Tempfile.new("iers", dest_path.dirname.to_s)
      tempfile.binmode
      tempfile.write(body)
      tempfile.close
      File.rename(tempfile.path, dest_path.to_s)
    rescue
      tempfile&.close!
      raise
    end
  end
end
