# frozen_string_literal: true

require "test_helper"

class TestData < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir("iers-test")
    IERS.configure do |config|
      config.cache_dir = @tmpdir
    end
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
    IERS.reset_configuration!
  end

  def test_update_finals_downloads_to_cache_dir
    stub_request(
      :get,
      "https://datacenter.iers.org/data/latestVersion/finals.all.iau2000.txt"
    ).to_return(status: 200, body: "finals data content")

    IERS::Data.update!(:finals)

    assert_equal "finals data content",
      Pathname(@tmpdir).join("finals2000A.all").read
  end

  def test_update_finals_returns_successful_result
    stub_request(
      :get,
      "https://datacenter.iers.org/data/latestVersion/finals.all.iau2000.txt"
    ).to_return(status: 200, body: "finals data content")

    result = IERS::Data.update!(:finals)

    assert_predicate result, :success?
  end

  def test_update_finals_includes_finals_in_updated_files
    stub_request(
      :get,
      "https://datacenter.iers.org/data/latestVersion/finals.all.iau2000.txt"
    ).to_return(status: 200, body: "finals data content")

    result = IERS::Data.update!(:finals)

    assert_equal [:finals], result.updated_files
  end

  def test_update_leap_seconds_downloads_to_cache_dir
    stub_request(:get, "https://hpiers.obspm.fr/iers/bul/bulc/Leap_Second.dat")
      .to_return(status: 200, body: "leap second data")

    IERS::Data.update!(:leap_seconds)

    assert_path_exists Pathname(@tmpdir).join("Leap_Second.dat")
  end

  def test_update_unknown_source_raises_configuration_error
    assert_raises(IERS::ConfigurationError) do
      IERS::Data.update!(:nonexistent)
    end
  end

  def test_update_single_file_network_error_is_not_successful
    stub_request(
      :get,
      "https://datacenter.iers.org/data/latestVersion/finals.all.iau2000.txt"
    ).to_return(status: 500)

    result = IERS::Data.update!(:finals)

    refute_predicate result, :success?
  end

  def test_update_single_file_network_error_collects_error
    stub_request(
      :get,
      "https://datacenter.iers.org/data/latestVersion/finals.all.iau2000.txt"
    ).to_return(status: 500)

    result = IERS::Data.update!(:finals)

    assert_instance_of IERS::NetworkError, result.errors[:finals]
  end

  def test_update_all_downloads_both_files
    stub_request(
      :get,
      "https://datacenter.iers.org/data/latestVersion/finals.all.iau2000.txt"
    ).to_return(status: 200, body: "finals data")
    stub_request(:get, "https://hpiers.obspm.fr/iers/bul/bulc/Leap_Second.dat")
      .to_return(status: 200, body: "leap data")

    result = IERS::Data.update!

    assert_includes result.updated_files, :finals
    assert_includes result.updated_files, :leap_seconds
  end

  def test_update_all_with_partial_failure_still_writes_successful_file
    stub_request(
      :get,
      "https://datacenter.iers.org/data/latestVersion/finals.all.iau2000.txt"
    ).to_return(status: 500)
    stub_request(:get, "https://hpiers.obspm.fr/iers/bul/bulc/Leap_Second.dat")
      .to_return(status: 200, body: "leap data")

    IERS::Data.update!

    assert_path_exists Pathname(@tmpdir).join("Leap_Second.dat")
  end

  def test_update_all_with_partial_failure_is_not_successful
    stub_request(
      :get,
      "https://datacenter.iers.org/data/latestVersion/finals.all.iau2000.txt"
    ).to_return(status: 500)
    stub_request(:get, "https://hpiers.obspm.fr/iers/bul/bulc/Leap_Second.dat")
      .to_return(status: 200, body: "leap data")

    result = IERS::Data.update!

    refute_predicate result, :success?
  end

  def test_update_finals_uses_custom_path_when_configured
    custom_path = Pathname(@tmpdir).join("custom", "my_finals.dat")
    IERS.configure { |c| c.finals_path = custom_path }
    stub_request(
      :get,
      "https://datacenter.iers.org/data/latestVersion/finals.all.iau2000.txt"
    ).to_return(status: 200, body: "custom finals data")

    IERS::Data.update!(:finals)

    assert_equal "custom finals data", custom_path.read
  end

  def test_update_finals_custom_path_does_not_write_to_default_location
    custom_path = Pathname(@tmpdir).join("custom", "my_finals.dat")
    IERS.configure { |c| c.finals_path = custom_path }
    stub_request(
      :get,
      "https://datacenter.iers.org/data/latestVersion/finals.all.iau2000.txt"
    ).to_return(status: 200, body: "custom finals data")

    IERS::Data.update!(:finals)

    refute_path_exists Pathname(@tmpdir).join("finals2000A.all")
  end

  def test_update_with_custom_source_url
    IERS.configure do |c|
      c.sources = {
        finals: "https://mirror.example.com/finals2000A.all",
        leap_seconds: "https://mirror.example.com/Leap_Second.dat"
      }
    end
    stub_request(:get, "https://mirror.example.com/finals2000A.all")
      .to_return(status: 200, body: "mirror finals data")

    IERS::Data.update!(:finals)

    assert_equal "mirror finals data",
      Pathname(@tmpdir).join("finals2000A.all").read
  end

  def test_status_without_cache_is_not_cached
    status = IERS::Data.status

    refute_predicate status, :cached?
  end

  def test_status_without_cache_has_nil_cache_age
    status = IERS::Data.status

    assert_nil status.cache_age
  end

  def test_status_with_cached_files_is_cached
    stub_request(
      :get,
      "https://datacenter.iers.org/data/latestVersion/finals.all.iau2000.txt"
    ).to_return(status: 200, body: "data")
    stub_request(:get, "https://hpiers.obspm.fr/iers/bul/bulc/Leap_Second.dat")
      .to_return(status: 200, body: "data")
    IERS::Data.update!

    status = IERS::Data.status

    assert_predicate status, :cached?
  end

  def test_status_with_cached_files_has_numeric_cache_age
    stub_request(
      :get,
      "https://datacenter.iers.org/data/latestVersion/finals.all.iau2000.txt"
    ).to_return(status: 200, body: "data")
    stub_request(
      :get,
      "https://hpiers.obspm.fr/iers/bul/bulc/Leap_Second.dat"
    ).to_return(status: 200, body: "data")
    IERS::Data.update!

    status = IERS::Data.status

    assert_kind_of Integer, status.cache_age
  end

  def test_status_with_custom_path_is_custom
    custom = Pathname(@tmpdir).join("custom_finals.dat")
    custom.dirname.mkpath
    custom.write("data")
    IERS.configure { |c| c.finals_path = custom }

    status = IERS::Data.status

    assert_equal :custom, status.source
  end

  def test_clear_cache_removes_cached_files
    stub_request(
      :get,
      "https://datacenter.iers.org/data/latestVersion/finals.all.iau2000.txt"
    ).to_return(status: 200, body: "finals data")
    stub_request(:get, "https://hpiers.obspm.fr/iers/bul/bulc/Leap_Second.dat")
      .to_return(status: 200, body: "leap data")
    IERS::Data.update!

    IERS::Data.clear_cache!

    refute_path_exists Pathname(@tmpdir).join("finals2000A.all")
    refute_path_exists Pathname(@tmpdir).join("Leap_Second.dat")
  end

  def test_clear_cache_does_not_remove_custom_path_files
    custom = Pathname(@tmpdir).join("custom", "finals.dat")
    custom.dirname.mkpath
    custom.write("custom data")
    IERS.configure { |c| c.finals_path = custom }

    IERS::Data.clear_cache!

    assert_path_exists custom
  end

  def test_clear_cache_is_safe_when_no_cache_exists
    IERS::Data.clear_cache!
  end

  def test_finals_entries_returns_parsed_entries
    write_finals_fixture

    entries = IERS::Data.finals_entries

    assert_equal 1, entries.size
  end

  def test_finals_entries_returns_finals_entry_objects
    write_finals_fixture

    entries = IERS::Data.finals_entries

    assert_instance_of IERS::Parsers::Finals::Entry, entries.first
  end

  def test_finals_entries_uses_custom_path
    custom = Pathname(@tmpdir).join("custom", "my_finals.dat")
    custom.dirname.mkpath
    custom.write(finals_line)
    IERS.configure { |c| c.finals_path = custom }

    entries = IERS::Data.finals_entries

    assert_equal 1, entries.size
  end

  def test_finals_entries_raises_file_not_found_when_not_downloaded
    assert_raises(IERS::FileNotFoundError) do
      IERS::Data.finals_entries
    end
  end

  def test_leap_second_entries_returns_parsed_entries
    write_leap_second_fixture

    entries = IERS::Data.leap_second_entries

    assert_equal 1, entries.size
  end

  def test_leap_second_entries_returns_leap_second_entry_objects
    write_leap_second_fixture

    entries = IERS::Data.leap_second_entries

    assert_instance_of IERS::Parsers::LeapSecond::Entry, entries.first
  end

  def test_leap_second_entries_uses_custom_path
    custom = Pathname(@tmpdir).join("custom", "my_leap.dat")
    custom.dirname.mkpath
    custom.write("    41317.0    1  1 1972       10\n")
    IERS.configure { |c| c.leap_second_path = custom }

    entries = IERS::Data.leap_second_entries

    assert_equal 1, entries.size
  end

  def test_leap_second_entries_raises_file_not_found_when_not_downloaded
    assert_raises(IERS::FileNotFoundError) do
      IERS::Data.leap_second_entries
    end
  end

  private

  def finals_line
    "73 1 2 41684.00 I  0.120733 0.009786  0.136966 0.015902  I 0.8084178 0.0002710  0.0000 0.1916  P    -0.766    0.199    -0.720    0.300   .143000   .137000   .8075000   -18.637    -3.667\n"
  end

  def write_finals_fixture
    Pathname(@tmpdir).join("finals2000A.all").write(finals_line)
  end

  def write_leap_second_fixture
    Pathname(@tmpdir).join("Leap_Second.dat")
      .write("    41317.0    1  1 1972       10\n")
  end
end
