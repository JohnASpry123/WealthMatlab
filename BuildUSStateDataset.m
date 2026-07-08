function data = BuildUSStateDataset(startYear, endYear, outFile)
% BuildUSStateDataset Download and assemble U.S. state panel data.
%
% This function builds the dataset needed for the U.S. state replication
% exercise in Fernandez-Villaverde, Ventura, and Yao (2025):
%   - Real GDP by state (BEA, chained 2017 dollars)
%   - Total population by state (Census)
%   - Working-age population by state, ages 15-64 (Census)
%
% The output is a struct with state-level fields and variable vectors:
%   data.(state).year
%   data.(state).Y
%   data.(state).pop
%   data.(state).pop_w
%   data.(state).y_pop
%   data.(state).y_w
%
% Inputs
%   startYear (scalar, optional): first year in sample, default 1997.
%   endYear   (scalar, optional): last year in sample, default current year-1.
%   outFile   (char,   optional): MAT output path, default data/USStatesData.mat.
%
% Notes
%   1) BEA and Census APIs can change field names over time. This function
%      includes basic validation and explicit error messages to keep the
%      pipeline reproducible and debuggable.
%   2) Working-age population is defined as ages 15 to 64.

    if nargin < 1 || isempty(startYear)
        startYear = 1997;
    end
    if nargin < 2 || isempty(endYear)
        endYear = year(datetime('today')) - 1;
    end
    if nargin < 3 || isempty(outFile)
        outFile = fullfile('data', 'USStatesData.mat');
    end

    if endYear < startYear
        error('endYear must be >= startYear.');
    end

    if ~exist('data', 'dir')
        mkdir('data');
    end

    years = (startYear:endYear)';

    gdpTable = fetchBEARealGDPByState(years);
    [popTable, popWTable] = fetchCensusPopulationByState(years);

    states = intersect(intersect(unique(gdpTable.state), unique(popTable.state)), unique(popWTable.state));
    states = sort(states);

    data = struct();
    for i = 1:numel(states)
        stateName = states{i};
        fieldName = matlab.lang.makeValidName(stateName);

        gdpRows = strcmp(gdpTable.state, stateName);
        popRows = strcmp(popTable.state, stateName);
        popWRows = strcmp(popWTable.state, stateName);

        Y = nan(numel(years), 1);
        pop = nan(numel(years), 1);
        pop_w = nan(numel(years), 1);

        [~, idxY] = ismember(gdpTable.year(gdpRows), years);
        [~, idxP] = ismember(popTable.year(popRows), years);
        [~, idxW] = ismember(popWTable.year(popWRows), years);

        Y(idxY(idxY > 0)) = gdpTable.value(gdpRows);
        pop(idxP(idxP > 0)) = popTable.value(popRows);
        pop_w(idxW(idxW > 0)) = popWTable.value(popWRows);

        if any(isnan(Y)) || any(isnan(pop)) || any(isnan(pop_w))
            missingYears = years(isnan(Y) | isnan(pop) | isnan(pop_w));
            error('Missing values for state %s in years: %s', stateName, mat2str(missingYears'));
        end

        data.(fieldName).state = stateName;
        data.(fieldName).year = years;
        data.(fieldName).Y = Y;
        data.(fieldName).pop = pop;
        data.(fieldName).pop_w = pop_w;
        data.(fieldName).y_pop = Y ./ pop;
        data.(fieldName).y_w = Y ./ pop_w;
    end

    metadata = struct();
    metadata.startYear = startYear;
    metadata.endYear = endYear;
    metadata.generatedOnUTC = char(datetime('now', 'TimeZone', 'UTC'));
    metadata.sources = struct( ...
        'bea', 'BEA Regional API, annual real GDP by state (chained 2017 dollars)', ...
        'census_total_pop', 'Census API PEP population endpoint', ...
        'census_working_age', 'Census API PEP charage endpoint, ages 15-64');

    save(outFile, 'data', 'metadata');
end

function out = fetchBEARealGDPByState(years)
% Attempt a small set of BEA table names used historically for annual
% state real GDP in chained 2017 dollars. Keep first that validates.

    tableCandidates = {'SAGDP9N', 'SAGDP9', 'SQGDP9'};
    beaData = [];

    for i = 1:numel(tableCandidates)
        tbl = tableCandidates{i};
        try
            params = struct();
            params.UserID = 'sampleUser';
            params.method = 'GetData';
            params.datasetname = 'Regional';
            params.TableName = tbl;
            params.LineCode = '1';
            params.GeoFIPS = 'STATE';
            params.Year = formatBEAYearList(years);
            params.ResultFormat = 'JSON';

            raw = webread('https://apps.bea.gov/api/data', params);
            if ~isfield(raw, 'BEAAPI') || ~isfield(raw.BEAAPI, 'Results') || ~isfield(raw.BEAAPI.Results, 'Data')
                continue
            end
            beaData = raw.BEAAPI.Results.Data;
            if ~isempty(beaData)
                break
            end
        catch
            % Try next candidate.
        end
    end

    if isempty(beaData)
        error('Unable to fetch BEA real GDP data. Check BEA API availability and table names.');
    end

    n = numel(beaData);
    state = cell(n,1);
    yearVec = nan(n,1);
    value = nan(n,1);

    for i = 1:n
        state{i} = strtrim(beaData(i).GeoName);
        yearVec(i) = str2double(beaData(i).TimePeriod);
        value(i) = str2double(strrep(beaData(i).DataValue, ',', ''));
    end

    keep = ~strcmp(state, 'United States') & ~contains(state, 'Region') & ~isnan(yearVec) & ~isnan(value);
    out = table(state(keep), yearVec(keep), value(keep), 'VariableNames', {'state', 'year', 'value'});

    % Keep only the requested year window and contiguous U.S. states + AK, HI.
    out = out(out.year >= years(1) & out.year <= years(end), :);
end


function yearList = formatBEAYearList(years)
% BEA interprets comma-separated Year values as an explicit list, not a
% numeric range, so include every requested sample year in the query.

    yearList = sprintf('%d,', years);
    yearList = yearList(1:end-1);
end

function [popOut, popWOut] = fetchCensusPopulationByState(years)

    popAll = table();
    popWAll = table();

    % Exclude non-state territories and DC for 50-state sample.
    excludedFips = {'11','60','66','69','72','78'};

    for y = years'
        total = fetchCensusTotalPopulation(y);
        work = fetchCensusWorkingAgePopulation(y);

        total = total(~ismember(total.state_fips, excludedFips), :);
        work = work(~ismember(work.state_fips, excludedFips), :);

        total.year = repmat(y, height(total), 1);
        work.year = repmat(y, height(work), 1);

        popAll = [popAll; total]; %#ok<AGROW>
        popWAll = [popWAll; work]; %#ok<AGROW>
    end

    popOut = table(popAll.state, popAll.year, popAll.value, 'VariableNames', {'state','year','value'});
    popWOut = table(popWAll.state, popWAll.year, popWAll.value, 'VariableNames', {'state','year','value'});
end

function out = fetchCensusTotalPopulation(y)
    url = sprintf('https://api.census.gov/data/%d/pep/population', y);
    query = '?get=NAME,POP&for=state:*';

    raw = webread([url query]);
    if ~iscell(raw) || size(raw,2) < 3
        error('Unexpected Census total population format for year %d.', y);
    end

    raw = raw(2:end,:);
    state = raw(:,1);
    value = cellfun(@str2double, raw(:,2));
    state_fips = raw(:,3);

    out = table(state, state_fips, value, 'VariableNames', {'state','state_fips','value'});
end

function out = fetchCensusWorkingAgePopulation(y)
% Uses single-year-of-age counts and sums ages 15:64.
    url = sprintf('https://api.census.gov/data/%d/pep/charage', y);
    query = '?get=NAME,AGE,POP&for=state:*';

    raw = webread([url query]);
    if ~iscell(raw) || size(raw,2) < 4
        error('Unexpected Census charage format for year %d.', y);
    end

    raw = raw(2:end,:);
    state = raw(:,1);
    age = cellfun(@str2double, raw(:,2));
    pop = cellfun(@str2double, raw(:,3));
    state_fips = raw(:,4);

    valid = age >= 15 & age <= 64;
    T = table(state(valid), state_fips(valid), pop(valid), 'VariableNames', {'state','state_fips','pop'});

    [G, sName, sFips] = findgroups(T.state, T.state_fips);
    wPop = splitapply(@sum, T.pop, G);

    out = table(sName, sFips, wPop, 'VariableNames', {'state','state_fips','value'});
end
