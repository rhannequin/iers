# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"

Minitest::TestTask.create

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[test rubocop]

namespace :data do
  desc "Download the latest IERS data"
  task :update do
    require "iers"

    data_dir = File.expand_path("data", __dir__)
    IERS.configure do |config|
      config.finals_path = File.join(data_dir, "finals2000A.all")
      config.leap_second_path = File.join(data_dir, "Leap_Second.dat")
    end

    result = IERS::Data.update!

    unless result.success?
      result.errors.each do |source, error|
        warn "#{source}: #{error.class} - #{error.message}"
      end
      abort "IERS data update failed"
    end

    IERS::Data.clear_loaded!
    IERS::Data.ensure_fresh!(coverage_days_ahead: 90)
    IERS::Data.leap_second_entries

    puts "Updated: #{result.updated_files.join(", ")}"
  end
end
