function out = parseCensus(file, kind, years)
% Resident population, July 1; both denominators from the same age cells.
% kind: 'intercensal1990', 'intercensal2000', or 'alldata6'.
[fips,~] = usstates.states();
out = table();
if strcmp(kind,'intercensal1990')
    fid = fopen(file,'r');
    assert(fid >= 0, 'usstates:File', 'Cannot open Census file.');
    cleanup = onCleanup(@() fclose(fid));
    c = textscan(fid,'%f%f%f%f%f%f','CollectOutput',true);
    a = c{1};
    assert(size(a,2)==6 && ~isempty(a) && all(isfinite(a(:))) && ...
        all(a(:)==fix(a(:))) && all(a(:,6)>=0), ...
        'usstates:CensusSchema','Invalid 1990s Census records.');
    assert(numel(years)==1 && all(a(:,1)+1900 == years), ...
        'usstates:CensusDate','Wrong year in Census file.');
    geo = a(:,2); state = floor(geo/1000);
    assert(all(mod(geo,1000)>0), 'usstates:CensusGeography', ...
        'Expected county cells only; do not double-count state totals.');
    keys = a(:,2:5);
    assert(size(unique(keys,'rows'),1)==size(keys,1), ...
        'usstates:CensusDuplicate','Duplicate county demographic cells.');
    assert(all(ismember(a(:,3),0:18)) && all(ismember(a(:,4),1:8)) && ...
        all(ismember(a(:,5),1:2)), 'usstates:CensusCategories','Unknown demographic code.');
    [~,~,g] = unique(geo);
    assert(all(accumarray(g,1)==19*8*2), ...
        'usstates:CensusCoverage','Incomplete age/race-sex/origin cells for a county.');
    for i=1:numel(fips)
        rows = state==fips(i);
        p = sum(a(rows,6));
        w = sum(a(rows & a(:,3)>=4 & a(:,3)<=13,6)); % exactly ages 15-64
        out = [out; table(fips(i),years,p,w,'VariableNames',{'fips','year','pop','pop_w'})]; %#ok<AGROW>
    end
else
    t = readtable(file);
    assert(all(ismember({'STATE','SEX','AGE'},t.Properties.VariableNames)), ...
        'usstates:CensusSchema','Missing Census columns.');
    if strcmp(kind,'alldata6')
        assert(all(ismember({'SUMLEV','ORIGIN','RACE'},t.Properties.VariableNames)), ...
            'usstates:CensusSchema','Missing ALLDATA6 dimensions.');
        % Six mutually exclusive races, total sex and origin. Never ALLDATA5.
        t = t(t.SUMLEV==40 & t.SEX==0 & t.ORIGIN==0 & ismember(t.STATE,fips),:);
        keys = [t.STATE,t.AGE,t.RACE];
        [s,a,r] = ndgrid(fips,0:85,1:6);
        expected = [s(:),a(:),r(:)];
    elseif strcmp(kind,'intercensal2000')
        t = t(t.SEX==0 & ismember(t.STATE,fips),:);
        totals = t(t.AGE==999,:);
        t = t(t.AGE~=999,:);
        keys = [t.STATE,t.AGE];
        [s,a] = ndgrid(fips,0:85); expected = [s(:),a(:)];
        assert(height(totals)==50 && isequal(sort(totals.STATE),fips), ...
            'usstates:CensusCoverage','Missing or duplicate state total rows.');
    else
        error('usstates:CensusSchema','Unknown Census file kind.');
    end
    assert(isequal(sortrows(keys),sortrows(expected)), ...
        'usstates:CensusCoverage','Missing, duplicate or unexpected age/demographic cells.');
    for y=years(:)'
        col = sprintf('POPESTIMATE%d',y);
        assert(ismember(col,t.Properties.VariableNames), ...
            'usstates:CensusDate','Missing July 1 estimate column %s.',col);
        x = t.(col);
        assert(isnumeric(x) && all(isfinite(x) & x>=0 & x==fix(x)), ...
            'usstates:CensusValues','Invalid population counts.');
        for i=1:numel(fips)
            rows = t.STATE==fips(i);
            p = sum(x(rows)); w = sum(x(rows & t.AGE>=15 & t.AGE<=64));
            if strcmp(kind,'intercensal2000')
                assert(p==totals.(col)(totals.STATE==fips(i)), ...
                    'usstates:CensusTotal','Age cells do not reconcile to population total.');
            end
            out = [out; table(fips(i),y,p,w,'VariableNames',{'fips','year','pop','pop_w'})]; %#ok<AGROW>
        end
    end
end
usstates.checkGrid(out,years,{'pop','pop_w'});
assert(all(out.pop_w<=out.pop), 'usstates:Population','Working-age population exceeds total population.');
end
