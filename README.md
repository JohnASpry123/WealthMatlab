# WealthMatlab: two independent analyses

| Entry point | Purpose | Inputs |
| --- | --- | --- |
| `Main.m` | Original Fernández-Villaverde, Ventura, and Yao (2025) one-sector growth-model simulation, intended for Figure 5.1 and Table 5 | Original WDI/PWT workbooks; MATLAB Optimization Toolbox |
| `Main_Table1_BasicFacts.m`, `Main_Table2_Decomposition.m`, `Main_Table3_AlternativeDef.m` | Original international descriptive/decomposition exercises | Original WDI/PWT inputs |
| `BuildUSStateDataset.m`, then `Main_USStates.m` | U.S. state extension: GDP per resident and per working-age resident, growth comparisons and ranks | BEA annual real GDP; pinned Census resident population releases |

The state exercise is an empirical extension, **not a replication of the original model simulation**. It never calls or replaces the original model. The shared `growth.m` retains the original simple-return definition. The state extension uses `usstates.logGrowth` instead.

## Original international/model analysis

Use MATLAB from the repository root, with Optimization Toolbox (`fsolve` and `optimoptions`). Supply the original workbooks, then run:

```matlab
Main
```

Original defaults: USA, 1991–2019, time-varying working-age share, GDP-based growth, and constant U.S. labor share. The switches and country selection remain in `Main.m`.

Required inputs, as referenced by the original readers:

- Baseline: `data/20230817_WDI_G7.xlsx`, a sheet for each country code, five heading rows, then columns year, constant-dollar GDP, constant-local-currency GDP, PPP GDP, total population, working-age population.
- PWT option (`growthTFP=1`): `data/PWT100_<COUNTRY>.xlsx` or `data/PWT100_<COUNTRY>constLS.xlsx`. `ReadExcelPWT.m` drops the first row and first two columns, then reads year, `rgdpna` (millions), total population, working-age population, labor share, `rtfpna`, and `rkna`.
- Descriptive Tables 1–3: `RawData/20240807_WDI.xlsx`; see each original script and its readers for the specified ranges and columns.

**Existing reproducibility gaps:** these spreadsheets are not committed. `PlotPaper.m` is empty on the original main branch, so running `Main` alone cannot regenerate the published figure. The supplied `July 18 2025 Wei Yu Replication.mat` is a saved workspace, not a substitute for all source workbooks. Do not claim paper-level numerical or figure reproduction until the original inputs/plot implementation are supplied and results compared with the paper. The original spreadsheet readers use Windows-style paths; Windows MATLAB is the unmodified execution target. Portability changes are outside this preservation change.

All original `.m` files and the saved `.mat` workspace are preserved byte for byte against main commit `15d912cf8e2657cab9691001a7fc35fcf18dd804`. `tests/original_sha256.json` and the Python regression test enforce this. Neither a BEA key nor state data is needed to run the original analysis.

## U.S. states and validation

See [README_USStates.md](README_USStates.md) for acquisition, offline reruns, population definitions, formulas, ranking conventions, source links, and remaining checks.

```sh
python -m unittest discover -s tests -p 'test_*.py' -v
```

```matlab
results = runtests('tests/testUSStates.m');
assertSuccess(results)
```

GitHub Actions runs the original-file guards and offline MATLAB tests, including synthetic end-to-end construction, exports and plots. It does not require statistical API credentials or download research data. See [VALIDATION.md](VALIDATION.md) for the actual verification status and live-run commands.
