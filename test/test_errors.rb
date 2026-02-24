# frozen_string_literal: true

require "test_helper"

class TestErrors < Minitest::Test
  def test_error_inherits_from_standard_error
    assert_operator IERS::Error, :<, StandardError
  end

  def test_data_error_inherits_from_error
    assert_operator IERS::DataError, :<, IERS::Error
  end

  def test_download_error_inherits_from_error
    assert_operator IERS::DownloadError, :<, IERS::Error
  end

  def test_network_error_inherits_from_download_error
    assert_operator IERS::NetworkError, :<, IERS::DownloadError
  end

  def test_network_error_has_url_and_status_code
    err = IERS::NetworkError.new("fail", url: "http://x", status_code: 500)

    assert_equal "http://x", err.url
    assert_equal 500, err.status_code
    assert_equal "fail", err.message
  end

  def test_validation_error_inherits_from_download_error
    assert_operator IERS::ValidationError, :<, IERS::DownloadError
  end

  def test_validation_error_has_path_and_reason
    err = IERS::ValidationError.new("fail", path: "/tmp/x", reason: "empty")

    assert_equal "/tmp/x", err.path
    assert_equal "empty", err.reason
    assert_equal "fail", err.message
  end

  def test_configuration_error_inherits_from_error
    assert_operator IERS::ConfigurationError, :<, IERS::Error
  end
end
