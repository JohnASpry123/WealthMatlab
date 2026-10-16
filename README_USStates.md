# U.S. state extension (1997–2025)

This MATLAB extension compares real GDP growth per resident and per working-age resident across the **50 states, including Alaska and Hawaii; excluding DC, territories, regions and the U.S. aggregate**. It is separate from the international growth-model simulation in `Main.m`. It does not reproduce the simulation's Figure 5.1 or Table 5.

## Run

Use MATLAB R2024b (CI target) with its JVM enabled. The state extension needs no Optimization or Statistics Toolbox. Run from the repository root or add that directory to the MATLAB path. Default paths are anchored to that directory, not the caller's working directory.

Obtain an active [BEA API key](https://apps.bea.gov/api/signup/) and set the `BEA_API_KEY` environment variable locally. Do not commit the key. The old `sampleUser` credential is inactive. Census bulk downloads need no Census API key.

```matlab
% Acquisition is explicit; it never happens as a side effect of analysis.
BuildUSStateDataset(1997, 2025);
Main_USStates(1997, 2025);

% Any fully covered subperiod, with a separate output directory:
Main_USStates(2011, 2019, [], fullfile('output','states_2011_2019'));

% Headless numerical/export run without graphics:
Main_USStates(1997, 2025, [], [], false);
```

`BuildUSStateDataset(startYear,endYear,outFile,cacheDir,offline)` creates parent directories for custom output paths. Defaults are `data/USStatesData.mat` and `data/us_states_raw/`. The sample is pinned to 1997–2025, not the moving current year. Any unreleased/missing GDP observation is an error, not a silently shortened sample. Future Census vintages require an explicit source/parser review.

For an offline reconstruction from archived source files and their JSON sidecars:

```matlab
BuildUSStateDataset(1997,2025,fullfile('data','USStatesData.mat'), ...
    fullfile('data','us_states_raw'),true);
Main_USStates(1997,2025);
```

BEA caches are request-window specific. A cache built for 1997–2025 can support analysis of any subperiod through the saved MAT file; rebuilding from raw BEA data for a different request window needs that window's raw cache. Analysis and `ReadDataUSStates` never use the network. Archive the raw directory, MAT dataset, code commit and outputs together. Generated data/output files are intentionally not committed.

## Sources and population definition

Total and working-age populations always come from **the same resident-population age cells and source vintage for a given year**, as of July 1. Working age means **15–64 inclusive**, not employment, labor force participation, or ages 16–64. No ACS observations, civilian-only series, April 1 census/base counts, interpolation, or extrapolation are substituted.

| Analysis years | Pinned Census source | Construction |
| --- | --- | --- |
| 1997–1999 | `stch-icen1997.txt` through `stch-icen1999.txt`, 1990–2000 intercensal estimates | Sum county cells over mutually exclusive race-sex and Hispanic-origin categories. Total: age groups 0–18. Working age: groups 4–13 (15–19 through 60–64). Require all 304 demographic cells per county and unique keys. |
| 2000–2009 | `st-est00int-agesex.csv`, 2000–2010 intercensal release | `SEX=0`, ages 0–85 (85 is 85+); working age 15–64. Reconcile the sum to `AGE=999` total. Read only July 1 `POPESTIMATEyyyy` columns. |
| 2010–2019 | `SC-EST2020-ALLDATA6.csv`, vintage 2020 | `SUMLEV=40`, `SEX=0`, `ORIGIN=0`; sum the six mutually exclusive race categories and ages 0–85. Working age 15–64. Use only 2010–2019 columns. |
| 2020–2025 | `sc-est2025-alldata6.csv`, vintage 2025 | Same ALLDATA6 categories; use 2020–2025 July 1 columns. |

The parser verifies a complete age-by-race grid for every included state. It excludes non-state geographies by a fixed numeric FIPS list and joins GDP and population by FIPS/year, never by display names. ALLDATA5 race-in-combination counts must **not** be substituted: those race categories overlap.

**Vintage boundaries:** the series combines intercensal estimates with postcensal vintages. Changes across 1999/2000, 2009/2010 and especially 2019/2020 can include revision/base effects. This is a documented splice, not a claim of one harmonized Census vintage. Before publication, inspect boundary growth rates and compare rankings within each vintage segment (e.g., 2010–2019 and 2020–2025) and with alternative Census intercensal releases. No automatic smoothing hides those breaks.

Official source documentation:

- [1990s intercensal files](https://www.census.gov/data/datasets/time-series/demo/popest/intercensal-1990-2000-state-and-county-characteristics.html) and [layout](https://www2.census.gov/programs-surveys/popest/technical-documentation/file-layouts/1990-2000/stch-intercensal_layout.txt).
- [2000s intercensal files](https://www.census.gov/data/datasets/time-series/demo/popest/intercensal-2000-2010-state.html) and [layout](https://www2.census.gov/programs-surveys/popest/technical-documentation/file-layouts/2000-2010/intercensal/state/st-est00int-agesex.pdf).
- [Vintage 2020 archive](https://www2.census.gov/programs-surveys/popest/datasets/2010-2020/state/asrh/) and [layout](https://www2.census.gov/programs-surveys/popest/technical-documentation/file-layouts/2010-2020/sc-est2020-alldata6.pdf).
- [Vintage 2025 files](https://www.census.gov/data/datasets/time-series/demo/popest/2020s-state-detail.html) and [layout](https://www2.census.gov/programs-surveys/popest/technical-documentation/file-layouts/2020-2025/SC-EST2025-ALLDATA6.pdf).
- [BEA API documentation](https://apps.bea.gov/API/docs/index.htm).

## GDP, growth and rankings

BEA Regional **SAGDP9N, line 1**, all-industry annual real GDP is requested for every sample year. The explicit comma-separated year list preserves the July 8 fix. No fallback to a quarterly table or another GDP measure is permitted. The parser requires annual periods, series `SAGDP9N-1`, millions of chained 2017 dollars and unit multiplier 6, then multiplies by **1,000,000**. A rebase/schema change fails with an explanation.

For each state/year:

- `Y`: real GDP in chained 2017 **dollars**.
- `pop`, `pop_w`: resident population and residents aged 15–64, in persons.
- `y_pop = Y/pop`; `y_w = Y/pop_w`: chained dollars per person.
- `g_x = mean(diff(log(x))) = (log(x_end)-log(x_start))/(endYear-startYear)`: mean annual log growth, in decimals. Multiply by 100 for log percentage points; use `100*expm1(g_x)` for the equivalent compound annual percentage rate. This differs from the arithmetic mean of annual simple returns used by the original `growth.m`.

All states must share the same contiguous annual sample; growth needs at least two observations. There is no `omitnan`. Positive finite GDP/population, integer population counts, `pop_w <= pop`, derived-variable identities, unique keys and complete 50-state coverage are mandatory. Old unversioned MAT files are rejected and must be rebuilt because their units/denominators may be wrong.

Ranks are descending (1 is highest growth), with **average ranks for exact ties**, computed without Statistics Toolbox. No rounding is applied before ranking. Very close but unequal growth estimates can have different ranks; interpret ranks alongside growth magnitudes. Alphabetical ordering only determines how tied rows are displayed. `rank_diff = rank_g_y_pop - rank_g_y_w`: positive means a state ranks better under the working-age denominator.

Chained-dollar GDP measures state production, not resident income or welfare. State price levels are not spatially equalized by this calculation, and interstate commuting can affect output per resident. This analysis ranks **growth**, not cross-state purchasing-power-adjusted living standards.

## Outputs and provenance

Default `output/us_states/` contains:

- `USStates_AverageGrowth.csv`: state/FIPS, sample endpoints, number of annual intervals, five growth rates and both ranks/difference.
- `USStates_AverageGrowth.mat`: summary and metadata.
- `USStates_RunMetadata.json`: dataset checksum, source records, build/analysis windows and calculation conventions.
- `USStates_IndexPlots.png`, `USStates_RankScatter.png`, `USStates_RankDiffHistogram.png`: when plots enabled. Index labels use the actual start year.

Raw files have SHA-256 sidecars with URL and retrieval time. Existing caches are hash-verified and reused, not silently refreshed. BEA credentials/request echo are removed before the JSON response is cached. To obtain a revised BEA release, use a new cache/output directory and keep the prior snapshot. Checksums detect local changes; they do not establish that an upstream release has not been revised before the first download.

## Tests

See [VALIDATION.md](VALIDATION.md). Synthetic fixtures are deliberately artificial and must never be presented as economic findings. Offline tests cover source parsers, demographic boundaries, missing/duplicate keys, GDP units, growth identities, ties, loading, cache tampering, complete offline construction and output/plot generation. Original-model reproduction still needs the original inputs and plotting code described in [README.md](README.md).
