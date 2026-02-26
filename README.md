# IERS

[![Tests](https://github.com/rhannequin/iers/workflows/CI/badge.svg)](https://github.com/rhannequin/iers/actions?query=workflow%3ACI)

Access to Earth orientation parameters and time scale values from the
International Earth Rotation and Reference Systems Service (IERS).

## About IERS and Earth Orientation Parameters

The [IERS] is an international service that monitors the irregularities of
Earth's rotation and orientation in space. Because Earth's rotation is not
perfectly uniform, precise timekeeping, satellite navigation, and telescope
pointing all depend on regularly updated measurements.

The key quantities tracked by the IERS are known as **Earth Orientation
Parameters** (EOP):

- **Polar motion (x, y)** — the position of Earth's rotational pole relative
  to its crust, expressed in arcseconds. The pole wanders in a roughly circular
  path of a few tenths of an arcsecond over ~14 months (the Chandler wobble).
- **UT1−UTC** — the difference between astronomical time (UT1, tied to Earth's
  actual rotation angle) and coordinated universal time (UTC, maintained by
  atomic clocks). This difference drifts by up to ~0.9 s before a leap second
  is introduced to keep them close.
- **Leap seconds** — occasional one-second adjustments applied to UTC so that
  it stays within 0.9 s of UT1. Since 1972, 27 leap seconds have been added.

### Data files

This library works with two data files published by the IERS:

- **finals2000A** — a daily table spanning from 1973 to the present (plus
  predictions ~1 year ahead). Each row contains polar motion, UT1−UTC, and
  other EOP for one Modified Julian Date. Recent rows carry rapid "Series A"
  values; older rows also include refined "Bulletin B" values.
- **Leap_Second.dat** — the complete history of leap seconds with their
  effective dates and the cumulative TAI−UTC offset.

Both files are downloaded automatically by `IERS::Data.update!` and cached
locally.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add iers

If [Bundler] is not being used to manage dependencies, install the gem by
executing:

    $ gem install iers

## Usage

### Downloading data

Before querying, fetch the latest IERS data files:

```ruby
require "iers"

result = IERS::Data.update!
result.success? # => true
```

Downloaded files are cached in `~/.cache/iers/` by default.

### Polar motion

Query the pole position at any point in time:

```ruby
pm = IERS::PolarMotion.at(Time.utc(2020, 6, 15))
pm.x          # => 0.070979... (arcseconds)
pm.y          # => 0.456571... (arcseconds)
pm.observed?  # => true
```

Retrieve daily grid values over a date range:

```ruby
entries = IERS::PolarMotion.between(
  Date.new(2020, 1, 1),
  Date.new(2020, 1, 31)
)
entries.count  # => 31
```

#### Rotation matrix

Compute the polar motion rotation matrix W (IERS Conventions 2010, §5.4.1):

```ruby
w = IERS::PolarMotion.rotation_matrix_at(Time.utc(2020, 6, 15))
w.length     # => 3
w[0].length  # => 3
```

Returns a nested `Array` (3×3, row-major).

The matrix is also available on any `PolarMotion::Entry`:

```ruby
pm = IERS::PolarMotion.at(Time.utc(2020, 6, 15))
pm.rotation_matrix  # => same nested Array
```

### UT1−UTC

Query the difference between UT1 and UTC:

```ruby
entry = IERS::UT1.at(Time.utc(2020, 6, 15))
entry.ut1_utc    # => -0.178182...
entry.observed?  # => true
```

Daily grid values:

```ruby
entries = IERS::UT1.between(
  Date.new(2020, 1, 1),
  Date.new(2020, 1, 31)
)
```

### Celestial pole offsets

Query the celestial pole offset corrections (dX, dY):

```ruby
cpo = IERS::CelestialPoleOffset.at(Time.utc(2020, 6, 15))
cpo.x  # => dX correction (milliarcseconds)
cpo.y  # => dY correction (milliarcseconds)
```

### Length of day

Query the excess length of day:

```ruby
entry = IERS::LengthOfDay.at(Time.utc(2020, 6, 15))
entry.length_of_day  # => excess LOD (seconds)
entry.observed?      # => true
```

### Delta T

Compute Delta T (TT − UT1), available from 1972 onward:

```ruby
IERS::DeltaT.at(Time.utc(2020, 6, 15))  # => ~69.36 (seconds)
```

### Earth Rotation Angle

Compute ERA (IERS Conventions 2010, eq. 5.15). The UT1-UTC correction is
looked up internally:

```ruby
IERS::EarthRotationAngle.at(Time.utc(2020, 6, 15))  # => radians, in [0, 2π)
```

### Greenwich Mean Sidereal Time

Compute GMST (IERS Conventions 2010, eq. 5.32). Uses ERA internally and adds
the equinox-based polynomial evaluated at TT:

```ruby
IERS::GMST.at(Time.utc(2020, 6, 15))  # => radians, in [0, 2π)
```

### Earth Orientation Parameters (unified)

Query all EOP components at once:

```ruby
eop = IERS::EOP.at(Time.utc(2020, 6, 15))
eop.polar_motion_x   # => arcseconds
eop.polar_motion_y   # => arcseconds
eop.ut1_utc          # => seconds
eop.length_of_day    # => seconds
eop.celestial_pole_x # => milliarcseconds
eop.celestial_pole_y # => milliarcseconds
eop.observed?        # => true
eop.date             # => #<Date: 2020-06-15>
```

Retrieve daily EOP over a date range:

```ruby
entries = IERS::EOP.between(
  Date.new(2020, 1, 1),
  Date.new(2020, 1, 31)
)
```

### Leap seconds

Look up TAI−UTC at a given date:

```ruby
IERS::LeapSecond.at(Time.utc(2017, 1, 1))  # => 37.0 (seconds)
```

List all leap seconds:

```ruby
IERS::LeapSecond.all
# => [#<data IERS::LeapSecond::Entry effective_date=#<Date: 1972-01-01>, tai_utc=10.0>, ...]
```

### Time input

All query methods accept Ruby `Time`, `Date`, and `DateTime` objects as
positional arguments. You can also use keyword arguments for numeric Julian
Dates:

```ruby
IERS::UT1.at(mjd: 58849.0)        # Modified Julian Date
IERS::UT1.at(jd: 2458849.5)       # Julian Date
IERS::UT1.at(Time.utc(2020, 1, 1)) # Ruby Time
```

### Data freshness

Check that predictions cover enough of the future before relying on
query results:

```ruby
begin
  IERS::Data.ensure_fresh!(coverage_days_ahead: 90)
rescue IERS::StaleDataError => e
  puts "Predictions end #{e.predicted_until}, need #{e.required_until}"
  IERS::Data.update!
end
```

Without `coverage_days_ahead`, the check ensures predictions cover today.

### Data status and cache management

```ruby
status = IERS::Data.status
status.cached?    # => true if downloaded data exists
status.cache_age  # => age in seconds, or nil

IERS::Data.clear_cache!  # remove downloaded files
```

### Custom data paths

Point the gem at your own copies of the IERS data files:

```ruby
IERS.configure do |config|
  config.finals_path = "/path/to/finals2000A.all"
  config.leap_second_path = "/path/to/Leap_Second.dat"
end
```

### Configuration

```ruby
IERS.configure do |config|
  config.cache_dir = "/path/to/cache"
  config.interpolation = :linear   # default: :lagrange
  config.lagrange_order = 6        # default: 4
  config.download_timeout = 60     # default: 30 (seconds)
end
```

To fully reset configuration and cached data:

```ruby
IERS.reset!
```

### Error handling

All errors inherit from `IERS::Error`:

- `IERS::OutOfRangeError` — query outside data coverage
- `IERS::StaleDataError` — predictions don't extend far enough
- `IERS::FileNotFoundError` — data file not downloaded yet
- `IERS::NetworkError` — download failure
- `IERS::ConfigurationError` — invalid configuration

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake test` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and the created tag, and push the `.gem` file to [rubygems.org].

## License

The gem is available as open source under the terms of the [MIT License].

## Code of Conduct

Everyone interacting in the IERS Ruby project's codebases, issue trackers, chat
rooms and mailing lists is expected to follow the [code of conduct].

[IERS]: https://www.iers.org
[Bundler]: https://bundler.io
[rubygems.org]: https://rubygems.org
[MIT License]: https://opensource.org/licenses/MIT
[code of conduct]: https://github.com/rhannequin/iers/blob/main/CODE_OF_CONDUCT.md
