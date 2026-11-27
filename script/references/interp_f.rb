# frozen_string_literal: true

require "json"
require "open3"
require "tmpdir"
require_relative "../../lib/iers"
require_relative "c04"
require_relative "stats"

interp_f, path_0h = ARGV
abort "usage: #{$PROGRAM_NAME} interp.f eopc04.1962-now" unless path_0h

FIRST_DAY = 45_702
DAY_STEP = 317
HOURS = [1.5, 4.5, 7.5, 10.5, 13.5, 16.5, 19.5, 22.5].freeze
WINDOW = (-1..2)

rows = C04.parse(path_0h).to_h { |r| [r.mjd.to_i, r] }
leap_seconds = IERS::Parsers::LeapSecond
  .parse(File.expand_path("../../data/Leap_Second.dat", __dir__))
  .entries
  .map { |e| e.mjd.to_i }

days = FIRST_DAY.step(rows.keys.max - 3, DAY_STEP).map do |day|
  day += 5 while leap_seconds.any? { |l| l > day - 1 && l <= day + 2 }
  day
end

epochs = days.flat_map { |day| HOURS.map { |h| day + h / 24.0 } }

input = [epochs.size.to_s]
epochs.each do |t|
  input << format("%.17g", t)
  WINDOW.each do |offset|
    r = rows.fetch(t.floor + offset)
    input << format("%.2f %.6f %.6f %.7f", r.mjd, r.x, r.y, r.ut1_utc)
  end
end

output = Dir.mktmpdir do |dir|
  driver = File.join(dir, "driver")
  _, status = Open3.capture2e(
    "gfortran", "-O0", "-std=legacy", "-ffixed-line-length-none",
    "-o", driver,
    File.expand_path("interp_driver.f", __dir__), interp_f
  )
  abort "gfortran failed" unless status.success?

  out, status = Open3.capture2(driver, stdin_data: input.join("\n") + "\n")
  abort "driver failed" unless status.success?
  out
end

cases = output.lines.map do |line|
  t, xl, yl, ul, xo, yo, uo, xg, yg = line.split.map { |v| Float(v) }
  {
    "mjd" => t,
    "lagint" => [xl, yl, ul],
    "ocean_tides" => [xo, yo, uo],
    "libration" => [xg, yg]
  }
end

corrections = {
  "ocean_tides" => %w[x y ut1_utc].each_with_index.to_h do |q, i|
    [q, Stats.summarize(cases.map { |c| c["ocean_tides"][i] * 1e6 })]
  end,
  "libration" => %w[x y].each_with_index.to_h do |q, i|
    [q, Stats.summarize(cases.map { |c| c["libration"][i] * 1e6 })]
  end,
  "total" => %w[x y].each_with_index.to_h do |q, i|
    [q, Stats.summarize(cases.map { |c| (c["ocean_tides"][i] + c["libration"][i]) * 1e6 })]
  end
}

fixture = {
  "description" => "The IERS reference routine interp.f run on the EOP 20 " \
    "C04 series sampled at 0h UTC. LAGINT is its 4-point Lagrange " \
    "interpolation of x, y and UT1-UTC, which the gem's default should " \
    "reproduce. PMUT1_OCEANS gives the diurnal and semi-diurnal ocean tide " \
    "terms on x, y and UT1, PM_GRAVI the diurnal libration terms on x and y; " \
    "interp.f adds both to the LAGINT values, and the gem leaves them out. " \
    "The cases are #{HOURS.size} epochs per day, every #{DAY_STEP} days " \
    "from MJD #{FIRST_DAY}, moved forward past any day whose window spans " \
    "a leap second since interp.f interpolates UT1-UTC across the step. " \
    "Each case lists x (\"), y (\") and UT1-UTC (s) from LAGINT, the ocean " \
    "tide corrections in the same units, and the libration corrections on " \
    "x and y. Statistics are in microarcseconds and microseconds.",
  "source" => {
    "interp_f" => {
      "url" => "https://hpiers.obspm.fr/iers/models/interp.f",
      "last_modified" => "2022-06-14",
      "compiler" => Open3.capture2("gfortran", "-dumpfullversion").first.strip
    },
    "c04_0h" => {
      "file" => File.basename(path_0h),
      "title" => C04.title(path_0h),
      "url" => "https://hpiers.obspm.fr/iers/eop/eopc04/eopc04.1962-now",
      "last_modified" => "2026-11-26"
    }
  },
  "corrections" => corrections,
  "c04_0h" => days
    .flat_map { |day| WINDOW.map { |offset| rows.fetch(day + offset) } }
    .map { |r| [r.mjd, r.x, r.y, r.ut1_utc] },
  "cases" => cases
}

puts JSON.pretty_generate(fixture)
  .gsub(/\[\s+([-\d.e+]+),\s+([-\d.e+]+)(?:,\s+([-\d.e+]+))?(?:,\s+([-\d.e+]+))?\s+\]/) {
    "[" + Regexp.last_match.captures.compact.join(", ") + "]"
  }
