# frozen_string_literal: true

module IERS
  DataStatus = Data.define(:source, :cache_age) do
    def cached?
      source == :cached
    end
  end
end
