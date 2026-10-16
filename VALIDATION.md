# Verification record — 2026-10-16 UTC

## Completed in the editing environment

- **2 Python regression tests passed.** Every original MATLAB source file and the original saved MAT workspace matches main commit `15d912cf8e2657cab9691001a7fc35fcf18dd804` byte for byte. Both entry points exist.
- **MISS_HIT MATLAB parsing/lint passed for all 17 new/modified state and test files.** This is a static check, not MATLAB execution.
- **Six official Census files downloaded and independently audited with Python.** All requested observations cover 50 states, for a total of 1,450 state-years (1997–2025). Historical county demographic grids are complete, 2000s age sums match reported state totals, and both ALLDATA6 files contain the expected 86 ages × 6 mutually exclusive races for every state under total-sex/total-origin filters. All working-age counts are positive and no greater than total population. Source URLs, raw row counts and SHA-256 fingerprints are recorded in `tests/census_source_audit_2026-10-16.jsonl`. This audit verifies the live source schemas independently; it does **not** execute the MATLAB parsers.
- BEA's endpoint was reachable. A probe using the PR's old `sampleUser` value returned API error 4 (inactive UserID). Successful live GDP acquisition was therefore **not** verified. No economic rankings are claimed from synthetic data.
- `git diff --check` against main passed.

## MATLAB tests supplied

`tests/testUSStates.m` has 17 offline tests covering:

- Original simple returns versus state-only log growth, and the complete 1997–2025 BEA year list.
- Dollar scaling, geographic filtering, annual-series checks, API errors, suppression, missing and duplicate state/year rows.
- FIPS/year alignment, balanced panels, positivity, population constraints, derived-variable identities and growth decomposition.
- Exact ties, date/category filtering, ages 15 and 64, incomplete/duplicate demographic cells, and total-population reconciliation.
- MAT version/coverage checks, one-year sample rejection, checksum validation and cache tampering.
- Full offline builder → saved dataset → reload → analysis using artificial source fixtures, nested output directories, CSV/MAT/metadata exports, and all three plots.

MATLAB and Octave are absent from this local environment. A GitHub Actions workflow is included to run the Python guards and all offline MATLAB tests on R2024b. **Check the PR's Actions result before treating the MATLAB suite as passed.** Static parsing and Python source audits do not replace MATLAB execution. Octave compatibility is not claimed (the pipeline uses MATLAB tables, datetime, JSON, JVM hashing and plotting).

## Commands and remaining live checks

From the repository root:

```sh
python -m unittest discover -s tests -p 'test_*.py' -v
# Optional live-source audit, Python standard library only:
python tests/check_census_sources.py /path/to/census-source-cache --download
# Optional static checker, if MISS_HIT is installed:
mh_lint --brief BuildUSStateDataset.m ReadDataUSStates.m Main_USStates.m +usstates tests/testUSStates.m
```

```matlab
results = runtests('tests/testUSStates.m');
assertSuccess(results)

% Needs network access and a registered BEA_API_KEY environment variable:
BuildUSStateDataset(1997,2025);
Main_USStates(1997,2025);

% Then reproduce the same snapshot with the network disabled:
BuildUSStateDataset(1997,2025,fullfile('data','USStatesData.mat'), ...
    fullfile('data','us_states_raw'),true);
Main_USStates(1997,2025);
```

The live MATLAB run must establish that the full BEA 1997–2025 sample is released and has the expected units/schema, validate source parsing in MATLAB, and compare exported numerical summaries across online/offline reruns. Archive the code commit, raw inputs and sidecars, dataset, and outputs. Use fresh cache/output directories for revised releases. Separately review Census vintage-boundary sensitivity before interpreting full-period rankings.

The original model still requires its missing WDI/PWT workbooks, Optimization Toolbox and the absent `PlotPaper.m` implementation for full paper-level reproduction; these are pre-existing gaps documented in `README.md`. Its code is preserved independently of all new state dependencies. No original numerical simulation or paper-figure reproduction is claimed here.
