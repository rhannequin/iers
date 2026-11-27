import json
import sys

import erfa
import numpy as np

if len(sys.argv) != 2:
    sys.exit(f"usage: {sys.argv[0]} eopc04.1962-now")

path_0h = sys.argv[1]
MJD0 = 2400000.5

rows = {}
with open(path_0h) as f:
    for line in f:
        if line.startswith("#") or not line.strip():
            continue
        fields = line.split()
        rows[int(float(fields[4]))] = [float(v) for v in fields[5:8]]

days = []
for year in range(1973, 2027):
    for month in (2, 5, 8, 11):
        mjd = int(erfa.cal2jd(year, month, 15)[1])
        if mjd + 5 in rows:
            days.append(mjd)

cases = []
for i, day in enumerate(days):
    mjd = day + ((i * 37) % 97) / 97
    x, y, ut1_utc = rows[day]
    ut1 = (MJD0, mjd + ut1_utc / 86400)
    tt = erfa.taitt(*erfa.utctai(MJD0, mjd))
    era = erfa.era00(*ut1)
    rpom = erfa.pom00(x * erfa.DAS2R, y * erfa.DAS2R, erfa.sp00(*tt))
    cases.append({
        "mjd": mjd,
        "x": x,
        "y": y,
        "ut1_utc": ut1_utc,
        "tai_utc": float(erfa.dat(*erfa.jd2cal(MJD0, mjd)[:3], 0.0)),
        "era00": era,
        "gmst06": erfa.gmst06(*ut1, *tt),
        "pom00": rpom.tolist(),
        "c2tcio": erfa.c2tcio(np.eye(3), era, rpom).tolist(),
    })

fixture = {
    "description": (
        "Earth Rotation Angle, Greenwich mean sidereal time and the polar "
        "motion and terrestrial rotation matrices from ERFA, for UTC dates "
        "on the 15th of February, May, August and November from 1973, at "
        "spread times of day. Each case carries the UT1-UTC (s) and pole "
        "coordinates (\") of the C04 series on that day, which the test "
        "hands to the gem, so both sides start from the same UT1 and only "
        "the formulas are compared. UT1 is UTC + UT1-UTC and TT is "
        "UTC + TAI-UTC + 32.184 s, as two-part Julian Dates. era00 and gmst06 "
        "are in radians. pom00 is the polar motion matrix W including the "
        "TIO locator s' from sp00, in ERFA's sense V(TRS) = W V(CIP). c2tcio "
        "is ERFA's celestial-to-terrestrial matrix with the CIRS as the "
        "celestial frame, W R3(ERA)."
    ),
    "source": {
        "pyerfa": erfa.__version__,
        "erfa": erfa.version.erfa_version,
        "sofa": erfa.version.sofa_version,
        "numpy": np.__version__,
        "c04_0h": {
            "file": path_0h.rsplit("/", 1)[-1],
            "url": "https://hpiers.obspm.fr/iers/eop/eopc04/eopc04.1962-now",
            "last_modified": "2026-11-26",
        },
        "method": (
            "era00(2400000.5, mjd + ut1_utc / 86400); "
            "gmst06(ut1, taitt(utctai(2400000.5, mjd))); "
            "pom00(x, y, sp00(tt)); c2tcio(identity, era, pom)"
        ),
    },
    "cases": "CASES",
}

print(json.dumps(fixture, indent=2).replace(
    '"CASES"',
    "[\n    " + ",\n    ".join(json.dumps(c) for c in cases) + "\n  ]",
))
