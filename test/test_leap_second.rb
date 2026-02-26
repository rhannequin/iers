# frozen_string_literal: true

require "test_helper"

class TestLeapSecond < Minitest::Test
  def setup
    IERS.configure do |config|
      config.leap_second_path = fixture_path("leap_second_query.dat")
    end
  end

  def teardown
    IERS.reset_configuration!
  end

  def fixture_path(name)
    Pathname(__dir__).join("fixtures", name)
  end

  def test_entry_has_effective_date
    entry = IERS::LeapSecond::Entry.new(
      effective_date: Date.new(1972, 1, 1),
      tai_utc: 10
    )

    assert_equal Date.new(1972, 1, 1), entry.effective_date
  end

  def test_entry_has_tai_utc
    entry = IERS::LeapSecond::Entry.new(
      effective_date: Date.new(1972, 1, 1),
      tai_utc: 10
    )

    assert_equal 10, entry.tai_utc
  end

  def test_entry_is_frozen
    entry = IERS::LeapSecond::Entry.new(
      effective_date: Date.new(1972, 1, 1),
      tai_utc: 10
    )

    assert_predicate entry, :frozen?
  end

  def test_all_returns_correct_count
    assert_equal 28, IERS::LeapSecond.all.size
  end

  def test_all_returns_entry_objects
    assert_instance_of IERS::LeapSecond::Entry,
      IERS::LeapSecond.all.first
  end

  def test_all_first_entry_effective_date
    assert_equal Date.new(1972, 1, 1),
      IERS::LeapSecond.all.first.effective_date
  end

  def test_all_first_entry_tai_utc
    assert_equal 10, IERS::LeapSecond.all.first.tai_utc
  end

  def test_all_last_entry_effective_date
    assert_equal Date.new(2017, 1, 1),
      IERS::LeapSecond.all.last.effective_date
  end

  def test_all_last_entry_tai_utc
    assert_equal 37, IERS::LeapSecond.all.last.tai_utc
  end

  def test_all_entries_are_sorted_by_effective_date
    entries = IERS::LeapSecond.all
    dates = entries.map(&:effective_date)

    assert_equal dates.sort, dates
  end

  def test_all_returns_frozen_array
    assert_predicate IERS::LeapSecond.all, :frozen?
  end

  def test_at_on_last_entry_date
    assert_equal 37, IERS::LeapSecond.at(Time.utc(2017, 1, 1))
  end

  def test_at_after_last_entry
    assert_equal 37, IERS::LeapSecond.at(Time.utc(2020, 6, 15))
  end

  def test_at_before_last_entry
    assert_equal 36, IERS::LeapSecond.at(Time.utc(2016, 12, 31))
  end

  def test_at_on_first_entry_date
    assert_equal 10, IERS::LeapSecond.at(Time.utc(1972, 1, 1))
  end

  def test_at_between_first_and_second_entry
    assert_equal 10, IERS::LeapSecond.at(Time.utc(1972, 3, 15))
  end

  def test_at_on_second_entry_date
    assert_equal 11, IERS::LeapSecond.at(Time.utc(1972, 7, 1))
  end

  def test_at_with_date_object
    assert_equal 37, IERS::LeapSecond.at(Date.new(2017, 1, 1))
  end

  def test_at_with_datetime_object
    assert_equal 37, IERS::LeapSecond.at(DateTime.new(2017, 1, 1))
  end

  def test_at_with_jd_keyword
    assert_equal 37, IERS::LeapSecond.at(jd: 2_457_754.5)
  end

  def test_at_with_mjd_keyword
    assert_equal 37, IERS::LeapSecond.at(mjd: 57754.0)
  end

  def test_at_returns_integer
    assert_instance_of Integer,
      IERS::LeapSecond.at(Time.utc(2017, 1, 1))
  end

  def test_at_before_1972_raises_out_of_range_error
    assert_raises(IERS::OutOfRangeError) do
      IERS::LeapSecond.at(Time.utc(1971, 12, 31))
    end
  end

  def test_at_before_1972_error_has_requested_mjd
    error = assert_raises(IERS::OutOfRangeError) do
      IERS::LeapSecond.at(Time.utc(1971, 12, 31))
    end

    assert_in_delta 41316.0, error.requested_mjd
  end

  def test_at_before_1972_error_has_available_range
    error = assert_raises(IERS::OutOfRangeError) do
      IERS::LeapSecond.at(Time.utc(1971, 12, 31))
    end

    assert_equal 41317.0..57754.0, error.available_range
  end

  def test_next_scheduled_returns_nil_when_no_future_entries
    assert_nil IERS::LeapSecond.next_scheduled
  end

  def test_next_scheduled_returns_entry_when_future_entry_exists
    IERS.configure do |config|
      config.leap_second_path = fixture_path("leap_second_with_future.dat")
    end

    result = IERS::LeapSecond.next_scheduled

    assert_instance_of IERS::LeapSecond::Entry, result
  end

  def test_next_scheduled_returns_correct_tai_utc
    IERS.configure do |config|
      config.leap_second_path = fixture_path("leap_second_with_future.dat")
    end

    result = IERS::LeapSecond.next_scheduled

    assert_equal 38, result.tai_utc
  end

  def test_next_scheduled_returns_correct_effective_date
    IERS.configure do |config|
      config.leap_second_path = fixture_path("leap_second_with_future.dat")
    end

    result = IERS::LeapSecond.next_scheduled

    assert_equal Date.new(2028, 7, 1), result.effective_date
  end

  def test_at_day_before_second_entry
    assert_equal 10, IERS::LeapSecond.at(Date.new(1972, 6, 30))
  end

  def test_at_far_in_future_returns_latest_known_value
    assert_equal 37, IERS::LeapSecond.at(Time.utc(2099, 1, 1))
  end

  def test_at_mid_year_between_two_entries
    assert_equal 11, IERS::LeapSecond.at(Date.new(1972, 10, 15))
  end

  def test_at_with_time_at_end_of_day
    assert_equal 36,
      IERS::LeapSecond.at(Time.utc(2016, 12, 31, 23, 59, 59))
  end

  def test_at_in_2006
    assert_equal 33, IERS::LeapSecond.at(Date.new(2006, 1, 1))
  end

  def test_at_between_2006_and_2009
    assert_equal 33, IERS::LeapSecond.at(Date.new(2007, 6, 15))
  end
end
