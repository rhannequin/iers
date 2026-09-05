# Changelog

## Unreleased

### Fixed

- `DeltaT.at` answers every date in 1972 again. The switch from the Espenak &
  Meeus polynomial to measured data was pinned to 1972-01-01, the start of the
  modern UTC era, but the bundled EOP series only starts at 1973-01-02, so the
  367 days in between belonged to neither source and raised `OutOfRangeError`.

### Changed

- `DeltaT.at` picks its source by asking what the loaded data actually covers
  rather than by calendar date. The EOP series is used wherever it reaches, the
  polynomial covers the rest of 1800–1986, and only a date outside both raises.
  A configured or extended series therefore moves the seam with it, and no
  fixed date can drift away from the data behind it again.

  Two consequences for a series that does not span the query. A date past the
  end of a short series now returns a polynomial estimate if it falls before
  1986, where it used to raise; this cannot arise with the bundled data, whose
  predictions run years ahead. And a date outside both sources now raises with
  a message naming the polynomial range and the series range, instead of the
  EOP range alone, which read as if the caller had asked for something out of
  range when the polynomial covered it.

  Where the polynomial and the series meet in the bundled data they differ by
  about 61 ms, well inside the polynomial's own error in that era.

- Pointing the gem at a different data file now takes effect. `finals_path`,
  `leap_second_path` and `cache_dir` memoised their parse on first read and
  never dropped it, so setting any of them after a lookup kept serving the
  previous file until `IERS.reset!`. Each now invalidates just the data it
  governs; `interpolation`, `sources` and `download_timeout` leave the parse
  in place, since they do not change which file is read.

- `Data.update!` drops the parse for each source as soon as it downloads it.
  It replaced the files on disk but left the old contents in memory, so a
  process that had already read them carried on with the pre-download data.

## 0.2.0 - 2026-07-25

### Added

- `LeapSecond.expires_on`, `LeapSecond.expired?` and
  `LeapSecond.updated_through` expose the expiry date and IERS bulletin that
  `Leap_Second.dat` states in its header. Both were previously discarded with
  the rest of the comment lines. Unlike `Data.status.cache_age`, which measures
  when a file was downloaded, these describe how long the data itself stays
  authoritative.
- `LeapSecond.at` now answers 1961-01-01 through 1972-01-01, the era when UTC
  was steered by rate adjustments rather than whole leap seconds. It returns
  those values as exact `Rational`s. The coefficients come from the USNO
  `tai-utc.dat` file and are bundled in source, since they are fixed. The
  change is additive: the pre-1972 range previously raised, so no successful
  call returns anything different. `TAI.utc_to_tai` and `TAI.tai_to_utc` gain
  the same range for free.

### Changed

- `Parsers::LeapSecond.parse` returns a `Table` of `entries` and `metadata`
  instead of an array of entries. `Parsers` is internal; the public API is
  unaffected.
- `Parsers::LeapSecond.parse` no longer raises `Encoding::CompatibilityError`
  on a file containing invalid UTF-8. Header metadata is read on a best-effort
  basis and an unreadable data row raises `ParseError` as before.

## 0.1.1 - 2026-06-27

### Changed

- Refreshed the bundled `finals2000A.all` snapshot from IERS. Final values now
  extend through 2026-06-25 (previously 2026-02-19) and predictions through
  2027-08-22.

## 0.1.0 - 2026-02-27

Initial public release.

### Features

- **Polar motion** - `PolarMotion.at` returns x/y coordinates with Lagrange or
  linear interpolation; `PolarMotion.rotation_matrix_at` builds the full W
  rotation matrix; `PolarMotion.between` for daily range queries
- **UT1-UTC** - `UT1.at` with automatic UT1-TAI normalization across leap second
  boundaries; Bulletin B preference over Series A when available
- **Celestial pole offsets** - `CelestialPoleOffset.at` for dX/dY corrections
- **Length of day** - `LengthOfDay.at` for LOD excess
- **Delta T** - `DeltaT.at` for TT - UT1, extended back to 1800 with
  Espenak & Meeus polynomials
- **Earth Rotation Angle** - `EarthRotationAngle.at` per IERS Conventions 2010
- **Greenwich Mean Sidereal Time** - `GMST.at` via ERA + polynomial
- **Terrestrial rotation** - `TerrestrialRotation.at` for the R(ERA) × W matrix
- **Unified EOP** - `EOP.at` and `EOP.between` composing all individual
  parameters
- **Leap seconds** - `LeapSecond.at` for TAI-UTC lookup with binary search;
  `LeapSecond.next_scheduled` for the next known transition
- **TAI utilities** - `TAI.utc_to_tai` and `TAI.tai_to_utc` for UTC↔TAI
  conversion
- **Bundled data** - ships a `finals2000A.all` and `Leap_Second.dat` snapshot
  for out-of-the-box usage with no network calls required
- **Data management** - `Data.update!` downloads fresh files with atomic writes
  and redirect handling; `Data.ensure_fresh!` raises `StaleDataError` when
  coverage is insufficient; `DataStatus` reports bundled/cached/custom state
- **Configuration** - `IERS.configure` for data paths, interpolation method
  (`:lagrange` or `:linear`), Lagrange order, freshness thresholds, and
  download URLs; per-query `interpolation:` override on all `.at` methods
- **Time inputs** - all query methods accept `Time`, `Date`, `DateTime`,
  Modified Julian Date (float), or Julian Date (float)
- **Data quality** - every `Entry` exposes `observed?` and `predicted?`
  predicates via the `HasDataQuality` mixin; `date` via `HasDate`
- **Lazy enumerators** - `between` returns a lazy `Enumerator` for
  memory-efficient iteration over large date ranges
- **Thread safety** - mutex-protected lazy caching in `Data` and `LeapSecond`
- **Error hierarchy** - `IERS::Error` base with `ConfigurationError`,
  `DataError`, `DownloadError`, `ParseError`, `FileNotFoundError`,
  `OutOfRangeError`, and `StaleDataError`
