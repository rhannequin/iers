# frozen_string_literal: true

module IERS
  # @api private
  module EopLookup
    module_function

    # @param entries [Array] sorted finals entries
    # @param mjd [Float]
    # @param order [Integer] number of points in the window
    # @return [Array]
    # @raise [OutOfRangeError]
    def window(entries, mjd, order: 4)
      validate_range!(entries, mjd)

      index = entries.bsearch_index { |e| e.mjd > mjd } || entries.size
      center = index - 1

      half = order / 2
      start = center - half + 1
      start = start.clamp(0, entries.size - order)

      entries[start, order]
    end

    # @param entries [Array] sorted finals entries
    # @param start_mjd [Float]
    # @param end_mjd [Float]
    # @return [Array] entries within the MJD range (inclusive)
    def range(entries, start_mjd, end_mjd)
      first = entries.bsearch_index { |e| e.mjd >= start_mjd } || entries.size
      last = entries.bsearch_index { |e| e.mjd > end_mjd } || entries.size
      entries[first...last]
    end

    # @param entries [Array] sorted finals entries
    # @param mjd [Float]
    # @return [Array] two-element array bracketing the query point
    # @raise [OutOfRangeError]
    def bracket(entries, mjd)
      validate_range!(entries, mjd)

      index = entries.bsearch_index { |e| e.mjd > mjd }

      if index.nil? || index == 0
        raise OutOfRangeError.new(
          "No bracket available for MJD #{mjd}",
          requested_mjd: mjd,
          available_range: entries.first.mjd..entries.last.mjd
        )
      end

      [entries[index - 1], entries[index]]
    end

    def validate_range!(entries, mjd)
      first_mjd = entries.first.mjd
      last_mjd = entries.last.mjd

      return if mjd.between?(first_mjd, last_mjd)

      raise OutOfRangeError.new(
        "Requested MJD #{mjd} is outside available data " \
        "(#{first_mjd}..#{last_mjd})",
        requested_mjd: mjd,
        available_range: first_mjd..last_mjd
      )
    end

    private_class_method :validate_range!
  end
end
