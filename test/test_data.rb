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

  # update! single file

  def test_update_finals_downloads_to_cache_dir
    stub_request(:get, "https://datacenter.iers.org/data/csv/finals2000A.all")
      .to_return(status: 200, body: "finals data content")

    IERS::Data.update!(:finals)

    assert_equal "finals data content",
      Pathname(@tmpdir).join("finals2000A.all").read
  end

  def test_update_finals_returns_successful_result
    stub_request(:get, "https://datacenter.iers.org/data/csv/finals2000A.all")
      .to_return(status: 200, body: "finals data content")

    result = IERS::Data.update!(:finals)

    assert_predicate result, :success?
  end

  def test_update_finals_includes_finals_in_updated_files
    stub_request(:get, "https://datacenter.iers.org/data/csv/finals2000A.all")
      .to_return(status: 200, body: "finals data content")

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
    stub_request(:get, "https://datacenter.iers.org/data/csv/finals2000A.all")
      .to_return(status: 500)

    result = IERS::Data.update!(:finals)

    refute_predicate result, :success?
  end

  def test_update_single_file_network_error_collects_error
    stub_request(:get, "https://datacenter.iers.org/data/csv/finals2000A.all")
      .to_return(status: 500)

    result = IERS::Data.update!(:finals)

    assert_instance_of IERS::NetworkError, result.errors[:finals]
  end

  # update! all files

  def test_update_all_downloads_both_files
    stub_request(:get, "https://datacenter.iers.org/data/csv/finals2000A.all")
      .to_return(status: 200, body: "finals data")
    stub_request(:get, "https://hpiers.obspm.fr/iers/bul/bulc/Leap_Second.dat")
      .to_return(status: 200, body: "leap data")

    result = IERS::Data.update!

    assert_includes result.updated_files, :finals
    assert_includes result.updated_files, :leap_seconds
  end

  def test_update_all_with_partial_failure_still_writes_successful_file
    stub_request(:get, "https://datacenter.iers.org/data/csv/finals2000A.all")
      .to_return(status: 500)
    stub_request(:get, "https://hpiers.obspm.fr/iers/bul/bulc/Leap_Second.dat")
      .to_return(status: 200, body: "leap data")

    IERS::Data.update!

    assert_path_exists Pathname(@tmpdir).join("Leap_Second.dat")
  end

  def test_update_all_with_partial_failure_is_not_successful
    stub_request(:get, "https://datacenter.iers.org/data/csv/finals2000A.all")
      .to_return(status: 500)
    stub_request(:get, "https://hpiers.obspm.fr/iers/bul/bulc/Leap_Second.dat")
      .to_return(status: 200, body: "leap data")

    result = IERS::Data.update!

    refute_predicate result, :success?
  end

  # update! with custom path overrides

  def test_update_finals_uses_custom_path_when_configured
    custom_path = Pathname(@tmpdir).join("custom", "my_finals.dat")
    IERS.configure { |c| c.finals_path = custom_path }
    stub_request(:get, "https://datacenter.iers.org/data/csv/finals2000A.all")
      .to_return(status: 200, body: "custom finals data")

    IERS::Data.update!(:finals)

    assert_equal "custom finals data", custom_path.read
  end

  def test_update_finals_custom_path_does_not_write_to_default_location
    custom_path = Pathname(@tmpdir).join("custom", "my_finals.dat")
    IERS.configure { |c| c.finals_path = custom_path }
    stub_request(:get, "https://datacenter.iers.org/data/csv/finals2000A.all")
      .to_return(status: 200, body: "custom finals data")

    IERS::Data.update!(:finals)

    refute_path_exists Pathname(@tmpdir).join("finals2000A.all")
  end

  # update! with custom source URLs

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

  # status

  def test_status_without_cache_is_not_cached
    status = IERS::Data.status

    refute_predicate status, :cached?
  end

  def test_status_without_cache_has_nil_cache_age
    status = IERS::Data.status

    assert_nil status.cache_age
  end

  def test_status_with_cached_files_is_cached
    stub_request(:get, "https://datacenter.iers.org/data/csv/finals2000A.all")
      .to_return(status: 200, body: "data")
    stub_request(:get, "https://hpiers.obspm.fr/iers/bul/bulc/Leap_Second.dat")
      .to_return(status: 200, body: "data")
    IERS::Data.update!

    status = IERS::Data.status

    assert_predicate status, :cached?
  end

  def test_status_with_cached_files_has_numeric_cache_age
    stub_request(:get, "https://datacenter.iers.org/data/csv/finals2000A.all")
      .to_return(status: 200, body: "data")
    stub_request(:get, "https://hpiers.obspm.fr/iers/bul/bulc/Leap_Second.dat")
      .to_return(status: 200, body: "data")
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

  # clear_cache!

  def test_clear_cache_removes_cached_files
    stub_request(:get, "https://datacenter.iers.org/data/csv/finals2000A.all")
      .to_return(status: 200, body: "finals data")
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
end
