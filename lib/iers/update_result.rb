# frozen_string_literal: true

module IERS
  # @attr updated_files [Array<Symbol>]
  # @attr errors [Hash{Symbol => Error}]
  UpdateResult = Data.define(:updated_files, :errors) do
    # @return [Boolean]
    def success?
      errors.empty?
    end
  end
end
