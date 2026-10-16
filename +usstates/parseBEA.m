function out = parseBEA(raw, years)
% Only SAGDP9N line 1 annual real GDP, converted from millions to dollars.
assert(isfield(raw,'BEAAPI') && isfield(raw.BEAAPI,'Results'), ...
    'usstates:BEASchema', 'Missing BEA Results.');
r = raw.BEAAPI.Results;
assert(~isfield(r,'Error') && isfield(r,'Data') && ~isempty(r.Data), ...
    'usstates:BEAResponse', 'BEA returned an error or no data; check your active BEA_API_KEY and requested years.');
rows = r.Data;
required = {'GeoFIPS','TimePeriod','DataValue','CL_UNIT','UNIT_MULT','Code'};
assert(all(isfield(rows, required)), 'usstates:BEASchema', 'BEA schema changed.');
fips = nan(numel(rows),1); yr = fips; value = fips;
for i = 1:numel(rows)
    geo = strtrim(char(string(rows(i).GeoFIPS)));
    if isempty(regexp(geo, '^\d{2}000$', 'once')), continue; end
    fips(i) = str2double(geo(1:2));
    if ~ismember(fips(i), usstates.states()), continue; end
    assert(strcmp(strtrim(char(string(rows(i).Code))), 'SAGDP9N-1'), ...
        'usstates:BEASeries', 'Expected annual all-industry SAGDP9N line 1.');
    unit = lower(strtrim(char(string(rows(i).CL_UNIT))));
    assert(strcmp(unit,'millions of chained 2017 dollars') && ...
        str2double(string(rows(i).UNIT_MULT)) == 6, ...
        'usstates:BEAUnits', 'GDP units/base year changed; review before updating parser.');
    period = char(string(rows(i).TimePeriod));
    assert(~isempty(regexp(period,'^\d{4}$','once')), ...
        'usstates:BEAFrequency', 'Expected annual GDP; quarterly data are not interchangeable.');
    yr(i) = str2double(period);
    value(i) = 1e6 * str2double(strrep(char(string(rows(i).DataValue)), ',', ''));
end
keep = ismember(fips,usstates.states()) & ismember(yr,years);
out = table(fips(keep),yr(keep),value(keep),'VariableNames',{'fips','year','Y'});
usstates.checkGrid(out, years, {'Y'});
end
