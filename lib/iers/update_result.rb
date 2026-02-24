# frozen_string_literal: true

module IERS
  UpdateResult = Data.define(:updated_files, :errors) do
    def success?
      errors.empty?
    end
  end
end
