# frozen_string_literal: true

module IERS
  # @attr source [Symbol] +:cached+, +:custom+, or +:bundled+
  # @attr cache_age [Integer, nil] age in seconds, or +nil+
  DataStatus = Data.define(:source, :cache_age) do
    # @return [Boolean]
    def cached?
      source == :cached
    end
  end
end
