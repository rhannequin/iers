# frozen_string_literal: true

module IERS
  module Data
    FILENAMES = {
      finals: "finals2000A.all",
      leap_seconds: "Leap_Second.dat"
    }.freeze

    BUNDLED_DIR = Pathname(__dir__).join("..", "..", "data").expand_path

    @mutex = Mutex.new
    @finals = nil
    @leap_second_table = nil

    module_function

    # @return [Boolean]
    def loaded?
      !@finals.nil? || !@leap_second_table.nil?
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
      @mutex.synchronize do
        @finals ||= begin
          path = resolve_read_path(:finals)
          Parsers::Finals.parse(path).freeze
        end
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
      end
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
      config.finals_path || config.leap_second_path
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

      @mutex.synchronize do
        @finals = nil if sources.include?(:finals)
        @leap_second_table = nil if sources.include?(:leap_seconds)
      end

      # Outside the mutex above: LeapSecond takes its own lock before calling
      # back into Data, so taking them in that order here would invert it.
      LeapSecond.clear_cached! if sources.include?(:leap_seconds)
    end

    private_class_method :resolve_path,
      :resolve_read_path,
      :validate_source!,
      :custom_paths_configured?,
      :cache_exists?,
      :oldest_cache_age
  end
end
