# U.S. States Replication Pipeline (1997 onward)

This extension builds a fully reproducible MATLAB data-and-analysis pipeline to replicate the cross-sectional growth comparison for U.S. states in the spirit of Fernandez-Villaverde, Ventura, and Yao (2025).

## What it does

1. Downloads data from official APIs:
   - **BEA Regional API**: annual real GDP by state (chained 2017 dollars).
   - **Census API**: annual total population by state.
   - **Census API**: annual working-age population by state (ages 15-64).
2. Constructs state-level variables:
   - `Y`: real GDP
   - `y_pop`: GDP per capita
   - `y_w`: GDP per working-age adult
   - `pop`: total population
   - `pop_w`: working-age population
3. Saves a MATLAB struct dataset in the format:
   - `data.(state).variable`
4. Runs a full analysis loop over states:
   - average log growth rates
   - index plots (1997=100)
   - scatter of `rank(g_y_pop)` vs `rank(g_y_w)`
   - histogram of rank differences

## Files

- `BuildUSStateDataset.m`: downloads and builds the state dataset, then saves `data/USStatesData.mat`.
- `ReadDataUSStates.m`: loads and filters the state dataset.
- `Main.m`: main reproducible pipeline and output generation.
- `growth.m`: log-difference growth function.

## Run instructions

From MATLAB:

```matlab
Main
```

The script will auto-build the dataset if `data/USStatesData.mat` does not exist.

## Outputs

Written to `output/`:

- `USStates_AverageGrowth.csv`
- `USStates_AverageGrowth.mat`
- `USStates_IndexPlots.png`
- `USStates_RankScatter.png`
- `USStates_RankDiffHistogram.png`

## Reproducibility notes

- All raw data are fetched programmatically from BEA and Census APIs.
- Working-age is consistently defined as ages 15 to 64.
- Growth rates are computed as log differences.
- If APIs change field names or table identifiers, the dataset builder returns explicit error messages for debugging and update.
