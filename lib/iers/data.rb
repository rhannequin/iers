# frozen_string_literal: true

module IERS
  module Data
    FILENAMES = {
      finals: "finals2000A.all",
      leap_seconds: "Leap_Second.dat"
    }.freeze

    module_function

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

    # @return [Array<Parsers::Finals::Entry>]
    def finals_entries
      path = resolve_path(:finals)
      Parsers::Finals.parse(path)
    end

    # @return [Array<Parsers::LeapSecond::Entry>]
    def leap_second_entries
      path = resolve_path(:leap_seconds)
      Parsers::LeapSecond.parse(path)
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

    private_class_method :resolve_path,
      :validate_source!,
      :custom_paths_configured?,
      :cache_exists?,
      :oldest_cache_age
  end
end
