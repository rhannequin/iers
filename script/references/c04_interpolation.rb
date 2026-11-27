# frozen_string_literal: true

require "json"
require "tmpdir"
require_relative "../../lib/iers"
require_relative "../../test/support/finals_file"
require_relative "c04"
require_relative "stats"

path_0h, path_12h = ARGV
abort "usage: #{$PROGRAM_NAME} eopc04.1962-now eopc04.12h.1984-now" unless path_12h

METHODS = {
  "linear" => {interpolation: :linear},
  "lagrange_4" => {interpolation: :lagrange, order: 4},
  "lagrange_6" => {interpolation: :lagrange, order: 6},
  "lagrange_8" => {interpolation: :lagrange, order: 8}
}.freeze
SAMPLE_STEP = 53
WINDOW = (-3..4)
PERIODS = {
  "1984-1993" => 45_700...49_353,
  "1994-2020" => 49_353...59_215,
  "2021-2024" => 59_215...60_676,
  "2025-" => 60_676...Float::INFINITY
}.freeze
SCALE = {"ut1_utc" => 1e6, "x" => 1e6, "y" => 1e6}.freeze

rows_0h = C04.parse(path_0h)
by_mjd = rows_0h.to_h { |r| [r.mjd.to_i, r] }
rows_12h = C04.parse(path_12h).select do |r|
  WINDOW.all? { |offset| by_mjd.key?(r.mjd.floor + offset) }
end

leap_seconds = IERS::Parsers::LeapSecond
  .parse(File.expand_path("../../data/Leap_Second.dat", __dir__))
  .entries
  .map { |e| e.mjd.to_i }
  .select { |mjd| mjd > rows_12h.first.mjd }

sample = rows_12h.each_slice(SAMPLE_STEP).map(&:first)
sample += rows_12h.select { |r| leap_seconds.any? { |l| (r.mjd - l).abs < 1 } }
sample = sample.uniq.sort_by(&:mjd)

def interpolate(rows_12h, method)
  IERS.configure { |c| c.lagrange_order = method[:order] } if method[:order]

  rows_12h.map do |r|
    ut1 = IERS::UT1.at(mjd: r.mjd, interpolation: method[:interpolation])
    pm = IERS::PolarMotion.at(mjd: r.mjd, interpolation: method[:interpolation])
    {
      "mjd" => r.mjd,
      "ut1_utc" => ut1.ut1_utc - r.ut1_utc,
      "x" => pm.x - r.x,
      "y" => pm.y - r.y
    }
  end
end

def summarize(differences)
  SCALE.to_h do |quantity, scale|
    [quantity, Stats.summarize(differences.map { |d| d[quantity] * scale })]
  end
end

full_series = {}
by_period = {}

Dir.mktmpdir do |dir|
  finals = File.join(dir, "finals")
  FinalsFile.write(finals, rows_0h.map { |r| [r.mjd, r.x, r.y, r.ut1_utc] })
  IERS.configure do |c|
    c.eop_source = :finals
    c.finals_path = finals
    c.leap_second_path = File.expand_path("../../data/Leap_Second.dat", __dir__)
  end

  METHODS.each do |name, method|
    differences = interpolate(rows_12h, method)
    full_series[name] = summarize(differences)
    by_period[name] = PERIODS.to_h do |period, range|
      [period, summarize(differences.select { |d| range.cover?(d["mjd"]) })]
    end
  end
end

sample_0h = sample
  .flat_map { |r| WINDOW.map { |offset| by_mjd.fetch(r.mjd.floor + offset) } }
  .uniq
  .sort_by(&:mjd)

fixture = {
  "description" => "UT1-UTC and polar motion of the IERS EOP 20 C04 series " \
    "sampled at 12h UTC, against the gem interpolating the same series " \
    "sampled at 0h UTC. Both files are the C04 2020 solution (readme, v4 of " \
    "2026-02-05). For x and y the 12h values are the primary ones from 1994: " \
    "they are the ITRF2020 values from 1994 to 2020, and from 2021 to 2024 " \
    "the 0h values are themselves interpolated from the 12h ones, so over " \
    "that period the difference measures two interpolations against each " \
    "other rather than one against the truth. UT1 has been Vondrak-smoothed " \
    "since 1984. The cases are every #{SAMPLE_STEP}th noon from the start of " \
    "the 12h series, plus the noons on either side of each leap second. " \
    "Each case carries the 0h values from 3 days before to 4 days after, " \
    "enough for every method listed. Differences are gem minus C04 12h, in " \
    "microseconds for UT1-UTC and microarcseconds for x and y.",
  "source" => {
    "c04_0h" => {
      "file" => File.basename(path_0h),
      "title" => C04.title(path_0h),
      "url" => "https://hpiers.obspm.fr/iers/eop/eopc04/eopc04.1962-now",
      "last_modified" => C04.last_modified(path_0h)
    },
    "c04_12h" => {
      "file" => File.basename(path_12h),
      "title" => C04.title(path_12h),
      "url" => "https://hpiers.obspm.fr/iers/eop/eopc04/eopc04.12h.1984-now",
      "last_modified" => C04.last_modified(path_12h)
    },
    "iers" => IERS::VERSION,
    "leap_seconds" => "data/Leap_Second.dat"
  },
  "full_series" => {
    "first_mjd" => rows_12h.first.mjd,
    "last_mjd" => rows_12h.last.mjd,
    "count" => rows_12h.size,
    "methods" => full_series,
    "by_period" => by_period
  },
  "c04_0h" => sample_0h.map { |r| [r.mjd, r.x, r.y, r.ut1_utc] },
  "cases" => sample.map { |r| [r.mjd, r.x, r.y, r.ut1_utc] }
}

puts JSON.pretty_generate(fixture)
  .gsub(/\[\s+([-\d.e+]+),\s+([-\d.e+]+),\s+([-\d.e+]+),\s+([-\d.e+]+)\s+\]/,
    '[\1, \2, \3, \4]')
