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

  def test_parse_error_inherits_from_data_error
    assert_operator IERS::ParseError, :<, IERS::DataError
  end

  def test_parse_error_has_path_and_line_number
    err = IERS::ParseError.new("bad line", path: "/tmp/f", line_number: 42)

    assert_equal "/tmp/f", err.path
    assert_equal 42, err.line_number
    assert_equal "bad line", err.message
  end

  def test_file_not_found_error_inherits_from_data_error
    assert_operator IERS::FileNotFoundError, :<, IERS::DataError
  end

  def test_file_not_found_error_has_path
    err = IERS::FileNotFoundError.new("missing", path: "/tmp/f")

    assert_equal "/tmp/f", err.path
    assert_equal "missing", err.message
  end

  def test_out_of_range_error_inherits_from_error
    assert_operator IERS::OutOfRangeError, :<, IERS::Error
  end

  def test_out_of_range_error_has_requested_mjd
    err = IERS::OutOfRangeError.new(
      "out of range",
      requested_mjd: 40000.0,
      available_range: 41317.0..57754.0
    )

    assert_in_delta 40000.0, err.requested_mjd
  end

  def test_out_of_range_error_has_available_range
    err = IERS::OutOfRangeError.new(
      "out of range",
      requested_mjd: 40000.0,
      available_range: 41317.0..57754.0
    )

    assert_equal 41317.0..57754.0, err.available_range
  end

  def test_out_of_range_error_has_message
    err = IERS::OutOfRangeError.new(
      "out of range",
      requested_mjd: 40000.0,
      available_range: 41317.0..57754.0
    )

    assert_equal "out of range", err.message
  end

  def test_stale_data_error_inherits_from_data_error
    assert_operator IERS::StaleDataError, :<, IERS::DataError
  end

  def test_stale_data_error_has_predicted_until
    err = IERS::StaleDataError.new(
      "stale",
      predicted_until: Date.new(2024, 1, 1),
      required_until: Date.new(2025, 1, 1)
    )

    assert_equal Date.new(2024, 1, 1), err.predicted_until
  end

  def test_stale_data_error_has_required_until
    err = IERS::StaleDataError.new(
      "stale",
      predicted_until: Date.new(2024, 1, 1),
      required_until: Date.new(2025, 1, 1)
    )

    assert_equal Date.new(2025, 1, 1), err.required_until
  end
end
