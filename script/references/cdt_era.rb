# frozen_string_literal: true

require "date"
require "json"
require "open3"

pdf = ARGV.first
abort "usage: #{$PROGRAM_NAME} CDT_2026_ebook.pdf" unless pdf

YEAR = 2026
HEADING = "ANGLE DE ROTATION DE LA TERRE #{YEAR} à 0h TU"
MONTHS = {
  "Janv." => 1, "Févr." => 2, "Mars" => 3, "Avril" => 4, "Mai" => 5,
  "Juin" => 6, "Juill." => 7, "Août" => 8, "Sept." => 9, "Oct." => 10,
  "Nov." => 11, "Déc." => 12
}.freeze
HALF_ROW = /
  (?:(?<month>\p{L}+\.?)\s+)?
  (?<day>\d{1,2})\s+
  (?<deg>\d{1,3})\s+(?<min>\d{1,2})\s+(?<sec>\d{1,2}\.\d{3}\s\d{2})\s+
  [−-]\s*\d+\s+\d{1,2}\.\d{3}\s\d{2}
/x

text, status = Open3.capture2("pdftotext", "-raw", "-enc", "UTF-8", pdf, "-")
abort "pdftotext failed" unless status.success?
text = text.force_encoding(Encoding::UTF_8).unicode_normalize(:nfc)

pages = text.split("\f").each_with_index.select { |page, _| page.include?(HEADING) }
abort "no ERA table found" if pages.empty?

entries = pages.flat_map do |page, _|
  left = []
  right = []
  page.each_line do |line|
    halves = line.to_enum(:scan, HALF_ROW).map { Regexp.last_match }
    next unless halves.size == 2

    left << halves[0]
    right << halves[1]
  end
  left + right
end

date = Date.new(YEAR - 1, 12, 30)
cases = entries.map do |m|
  date += 1
  if m[:day].to_i != date.day || (m[:month] && MONTHS.fetch(m[:month]) != date.month)
    abort "expected #{date}, read #{m[:month]} #{m[:day]}"
  end

  {
    "date" => date.iso8601,
    "mjd" => (date.jd - 2_400_001).to_f,
    "era" => [m[:deg].to_i, m[:min].to_i, Float(m[:sec].delete(" "))]
  }
end

fixture = {
  "description" => "Earth Rotation Angle at 0h UT1 for every day of " \
    "#{YEAR}, from the table \"Angle de rotation de la Terre, équation des " \
    "origines\" of the Connaissance des temps #{YEAR}, published by the " \
    "Bureau des longitudes and the Laboratoire Temps Espace (IMCCE). The " \
    "edition computes it with the IAU SOFA routines from the IAU 2000 " \
    "expression of ERA in UT1, and prints it in degrees, minutes and " \
    "seconds of arc to 0.00001\". The table heading says 0h TU; the daily " \
    "step is exactly ERA's rate over one UT1 day, so the dates are 0h UT1. " \
    "Each case lists the date, its MJD and the tabulated angle as " \
    "[degrees, minutes, seconds].",
  "source" => {
    "title" => "Connaissance des temps #{YEAR}",
    "url" => "https://www.imcce.fr/content/medias/publications/" \
      "publications-institutionnelles/CDT_#{YEAR}_ebook.pdf",
    "last_modified" => "2025-11-28",
    "pages" => "printed pages 10 to 13 (PDF pages " \
      "#{pages.first[1] + 1} to #{pages.last[1] + 1})",
    "extraction" => "pdftotext -raw " +
      Open3.capture2e("pdftotext", "-v").first[/\d+\.\d+\.\d+/].to_s
  },
  "cases" => "CASES"
}

puts JSON.pretty_generate(fixture).sub(
  '"CASES"',
  "[\n    " + cases.map { |c| JSON.generate(c) }.join(",\n    ") + "\n  ]"
)
