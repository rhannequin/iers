# frozen_string_literal: true

module IERS
  module Data
    FILENAMES = {
      finals: "finals2000A.all",
      leap_seconds: "Leap_Second.dat",
      c04: "eopc04.1962-now"
    }.freeze

    C04_CELESTIAL_POLE_START_MJD = 45700.0

    BUNDLED_DIR = Pathname(__dir__).join("..", "..", "data").expand_path

    @mutex = Mutex.new
    @finals = nil
    @eop = nil
    @leap_second_table = nil

    module_function

    # @return [Boolean]
    def loaded?
      [@finals, @eop, @leap_second_table].any?
    end

    # @param sources [Array<Symbol>] data sources to update (default: all)
    # @return [UpdateResult]
    def update!(*sources)
      config = IERS.configuration
      sources = config.sources.keys if sources.empty?

      updated = []
      errors = {}

      sources.each do |source|
        validate_source!(source, config)
        url = config.sources[source]
        dest = resolve_path(source, config)

        begin
          Downloader.new(timeout: config.download_timeout).fetch(url, dest)
          updated << source
          clear_loaded!(source)
        rescue DownloadError => e
          errors[source] = e
        end
      end

      UpdateResult.new(updated_files: updated, errors: errors)
    end

    # @return [DataStatus]
    def status
      config = IERS.configuration

      if custom_paths_configured?(config)
        DataStatus.new(source: :custom, cache_age: nil)
      elsif cache_exists?(config)
        age = oldest_cache_age(config)
        DataStatus.new(source: :cached, cache_age: age)
      else
        DataStatus.new(source: :bundled, cache_age: nil)
      end
    end

    # @return [void]
    def clear_cache!
      config = IERS.configuration

      FILENAMES.each_value do |filename|
        path = config.cache_dir.join(filename)
        path.delete if path.exist?
      end

      clear_loaded!
    end

    # @param coverage_days_ahead [Integer, nil]
    # @return [void]
    # @raise [StaleDataError]
    def ensure_fresh!(coverage_days_ahead: nil)
      predicted_until = finals_entries.last.date
      required_until = Date.today + (coverage_days_ahead || 0)

      return if predicted_until >= required_until

      raise StaleDataError.new(
        "Predictions only extend to #{predicted_until} " \
        "but coverage through #{required_until} is required",
        predicted_until: predicted_until,
        required_until: required_until
      )
    end

    # @return [Array<Parsers::Finals::Entry>]
    def finals_entries
      @mutex.synchronize { load_finals }
    end

    # @return [Array<Parsers::C04::Entry>]
    def c04_entries
      Parsers::C04.parse(resolve_read_path(:c04)).freeze
    end

    # @return [Array<Parsers::Finals::Entry>]
    def eop_entries
      source = IERS.configuration.eop_source

      @mutex.synchronize do
        if @eop.nil? || @eop[:source] != source
          @eop = {source: source, entries: build_eop_entries(source)}
        end

        @eop[:entries]
      end
    end

    # @return [Parsers::LeapSecond::Table]
    def leap_second_table
      @mutex.synchronize do
        @leap_second_table ||= begin
          path = resolve_read_path(:leap_seconds)
          Parsers::LeapSecond.parse(path)
        end
      end
    end

    # @return [Array<Parsers::LeapSecond::Entry>]
    def leap_second_entries
      leap_second_table.entries
    end

    # @return [Parsers::LeapSecond::Metadata]
    def leap_second_metadata
      leap_second_table.metadata
    end

    def resolve_path(source, config = IERS.configuration)
      case source
      when :finals
        config.finals_path || config.cache_dir.join(FILENAMES[:finals])
      when :leap_seconds
        config.leap_second_path ||
          config.cache_dir.join(FILENAMES[:leap_seconds])
      when :c04
        config.c04_path || config.cache_dir.join(FILENAMES[:c04])
      end
    end

    def load_finals
      @finals ||= Parsers::Finals.parse(resolve_read_path(:finals)).freeze
    end

    def build_eop_entries(source)
      return load_finals if source == :finals

      finals = @finals || Parsers::Finals.parse(resolve_read_path(:finals))
      c04 = read_c04
      return finals.freeze if c04.nil?

      by_mjd = c04.to_h { |entry| [entry.mjd, entry] }
      finals.map { |entry| overlay_c04(entry, by_mjd[entry.mjd]) }.freeze
    end

    def read_c04
      paths = [resolve_read_path(:c04), BUNDLED_DIR.join(FILENAMES[:c04])]

      paths.uniq.each do |path|
        return Parsers::C04.parse(path)
      rescue DataError, SystemCallError
        next
      end

      nil
    end

    def overlay_c04(entry, c04)
      return entry if c04.nil?
      return entry unless entry.pm_flag == "I" && entry.ut1_flag == "I"

      values = {
        pm_flag: "I",
        pm_x: c04.pm_x, pm_x_error: c04.pm_x_error,
        pm_y: c04.pm_y, pm_y_error: c04.pm_y_error,
        ut1_flag: "I",
        ut1_utc: c04.ut1_utc, ut1_utc_error: c04.ut1_utc_error,
        lod: c04.lod * 1000, lod_error: c04.lod_error * 1000,
        bulletin_b_pm_x: nil, bulletin_b_pm_y: nil, bulletin_b_ut1_utc: nil
      }

      if c04.mjd >= C04_CELESTIAL_POLE_START_MJD
        values.merge!(
          nutation_flag: "I",
          dx: c04.dx * 1000, dx_error: c04.dx_error * 1000,
          dy: c04.dy * 1000, dy_error: c04.dy_error * 1000,
          bulletin_b_dx: nil, bulletin_b_dy: nil
        )
      end

      entry.with(**values)
    end

    def resolve_read_path(source, config = IERS.configuration)
      path = resolve_path(source, config)
      return path if Pathname(path).exist?

      BUNDLED_DIR.join(FILENAMES[source])
    end

    def validate_source!(source, config)
      return if config.sources.key?(source)

      raise ConfigurationError,
        "Unknown data source: #{source.inspect}. Valid sources: #{config.sources.keys.inspect}"
    end

    def custom_paths_configured?(config)
      config.finals_path || config.leap_second_path || config.c04_path
    end

    def cache_exists?(config)
      FILENAMES.any? do |_, filename|
        config.cache_dir.join(filename).exist?
      end
    end

    def oldest_cache_age(config)
      mtimes = FILENAMES.filter_map do |_, filename|
        path = config.cache_dir.join(filename)
        path.mtime if path.exist?
      end

      return nil if mtimes.empty?

      (Time.now - mtimes.min).to_i
    end

    # @param sources [Array<Symbol>] data sources to drop (default: all)
    # @return [void]
    def clear_loaded!(*sources)
      sources = FILENAMES.keys if sources.empty?
      validate_sources!(sources)

      @mutex.synchronize do
        @finals = nil if sources.include?(:finals)
        @eop = nil if sources.intersect?(%i[finals c04])
        @leap_second_table = nil if sources.include?(:leap_seconds)
      end

      # Outside the mutex above: LeapSecond takes its own lock before calling
      # back into Data, so taking them in that order here would invert it.
      LeapSecond.clear_cached! if sources.include?(:leap_seconds)
    end

    def validate_sources!(sources)
      unknown = sources - FILENAMES.keys
      return if unknown.empty?

      raise ConfigurationError,
        "Unknown data source: #{unknown.map(&:inspect).join(", ")}. " \
        "Valid sources: #{FILENAMES.keys.inspect}"
    end

    private_class_method :validate_sources!,
      :resolve_path,
      :resolve_read_path,
      :load_finals,
      :read_c04,
      :build_eop_entries,
      :overlay_c04,
      :validate_source!,
      :custom_paths_configured?,
      :cache_exists?,
      :oldest_cache_age
  end
end
