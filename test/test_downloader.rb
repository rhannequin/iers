# frozen_string_literal: true

require "test_helper"

class TestDownloader < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir("iers-test")
    @dest = Pathname(@tmpdir).join("finals2000A.all")
    @downloader = IERS::Downloader.new(timeout: 30)
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
  end

  def test_downloads_file_to_destination
    stub_request(:get, "https://example.com/file.dat")
      .to_return(status: 200, body: "MJD data here\n")

    @downloader.fetch("https://example.com/file.dat", @dest)

    assert_equal "MJD data here\n", @dest.read
  end

  def test_creates_parent_directories
    nested = Pathname(@tmpdir).join("a", "b", "c", "file.dat")
    stub_request(:get, "https://example.com/file.dat")
      .to_return(status: 200, body: "data")

    @downloader.fetch("https://example.com/file.dat", nested)

    assert_path_exists nested
  end

  def test_no_partial_file_on_network_error
    stub_request(:get, "https://example.com/file.dat")
      .to_raise(Errno::ECONNRESET)

    assert_raises(IERS::NetworkError) do
      @downloader.fetch("https://example.com/file.dat", @dest)
    end

    refute_path_exists @dest
  end

  def test_follows_redirects
    stub_request(:get, "https://example.com/old")
      .to_return(status: 302, headers: {"Location" => "https://example.com/new"})
    stub_request(:get, "https://example.com/new")
      .to_return(status: 200, body: "redirected data")

    @downloader.fetch("https://example.com/old", @dest)

    assert_equal "redirected data", @dest.read
  end

  def test_too_many_redirects_raises_network_error
    url = "https://example.com/loop"
    stub_request(:get, url)
      .to_return(status: 302, headers: {"Location" => url})

    assert_raises(IERS::NetworkError) do
      @downloader.fetch(url, @dest)
    end
  end

  def test_http_error_raises_network_error
    stub_request(:get, "https://example.com/file.dat")
      .to_return(status: 404, body: "Not Found")

    assert_raises(IERS::NetworkError) do
      @downloader.fetch("https://example.com/file.dat", @dest)
    end
  end

  def test_http_error_exposes_status_code
    stub_request(:get, "https://example.com/file.dat")
      .to_return(status: 404, body: "Not Found")

    error = assert_raises(IERS::NetworkError) do
      @downloader.fetch("https://example.com/file.dat", @dest)
    end

    assert_equal 404, error.status_code
  end

  def test_http_error_exposes_url
    stub_request(:get, "https://example.com/file.dat")
      .to_return(status: 404, body: "Not Found")

    error = assert_raises(IERS::NetworkError) do
      @downloader.fetch("https://example.com/file.dat", @dest)
    end

    assert_equal "https://example.com/file.dat", error.url
  end

  def test_timeout_raises_network_error
    stub_request(:get, "https://example.com/file.dat")
      .to_timeout

    assert_raises(IERS::NetworkError) do
      @downloader.fetch("https://example.com/file.dat", @dest)
    end
  end

  def test_socket_error_raises_network_error
    stub_request(:get, "https://example.com/file.dat")
      .to_raise(SocketError.new("getaddrinfo: Name or service not known"))

    assert_raises(IERS::NetworkError) do
      @downloader.fetch("https://example.com/file.dat", @dest)
    end
  end

  def test_empty_response_raises_validation_error
    stub_request(:get, "https://example.com/file.dat")
      .to_return(status: 200, body: "")

    assert_raises(IERS::ValidationError) do
      @downloader.fetch("https://example.com/file.dat", @dest)
    end
  end

  def test_empty_response_validation_error_exposes_reason
    stub_request(:get, "https://example.com/file.dat")
      .to_return(status: 200, body: "")

    error = assert_raises(IERS::ValidationError) do
      @downloader.fetch("https://example.com/file.dat", @dest)
    end

    assert_equal "empty response body", error.reason
  end
end
