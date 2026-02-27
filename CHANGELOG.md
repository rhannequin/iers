# Changelog

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
