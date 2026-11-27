# Reference values

These scripts produce the fixtures in `test/fixtures/references/`, which the
tests in `test/references/` compare the gem with. They run once, by hand, on
files downloaded beforehand; the tests only read the fixtures.

Inputs:

- `eopc04.1962-now` and `eopc04.12h.1984-now` from
  <https://hpiers.obspm.fr/iers/eop/eopc04/>
- `interp.f` from <https://hpiers.obspm.fr/iers/models/interp.f>
- `CDT_2026_ebook.pdf` from the [IMCCE publications page][cdt]

Requirements: `gfortran` for `interp.f`, `pdftotext` (Poppler) for the
Connaissance des temps, and Python with `pyerfa` for ERFA.

```sh
ruby script/references/c04_interpolation.rb eopc04.1962-now eopc04.12h.1984-now \
  > test/fixtures/references/c04_interpolation.json
ruby script/references/interp_f.rb interp.f eopc04.1962-now \
  > test/fixtures/references/interp_f.json
python3 script/references/erfa_rotation.py eopc04.1962-now \
  > test/fixtures/references/erfa_rotation.json
ruby script/references/cdt_era.rb CDT_2026_ebook.pdf \
  > test/fixtures/references/cdt_era.json
```

The file dates recorded in each fixture's `source` are the `Last-Modified`
headers of the downloads, and are set in the scripts: update them along with
the files.

[cdt]: https://www.imcce.fr/content/medias/publications/publications-institutionnelles/CDT_2026_ebook.pdf
