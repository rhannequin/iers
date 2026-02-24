# frozen_string_literal: true

require "test_helper"

class TestUpdateResult < Minitest::Test
  def test_success_when_no_errors
    result = IERS::UpdateResult.new(updated_files: [:finals], errors: {})

    assert_predicate result, :success?
  end

  def test_not_success_when_errors_present
    result = IERS::UpdateResult.new(
      updated_files: [],
      errors: {finals: IERS::DownloadError.new("fail")}
    )

    refute_predicate result, :success?
  end

  def test_updated_files
    result = IERS::UpdateResult.new(
      updated_files: [:finals, :leap_seconds],
      errors: {}
    )

    assert_equal [:finals, :leap_seconds], result.updated_files
  end

  def test_errors
    err = IERS::DownloadError.new("fail")
    result = IERS::UpdateResult.new(updated_files: [], errors: {finals: err})

    assert_equal({finals: err}, result.errors)
  end

  def test_partial_success
    err = IERS::NetworkError.new("timeout", url: "http://x", status_code: nil)
    result = IERS::UpdateResult.new(
      updated_files: [:leap_seconds],
      errors: {finals: err}
    )

    refute_predicate result, :success?
    assert_equal [:leap_seconds], result.updated_files
    assert_instance_of IERS::NetworkError, result.errors[:finals]
  end
end
