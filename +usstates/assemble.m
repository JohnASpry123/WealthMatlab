function data = assemble(gdp, population, years)
usstates.checkGrid(gdp,years,{'Y'});
usstates.checkGrid(population,years,{'pop','pop_w'});
gdp = sortrows(gdp,{'fips','year'});
population = sortrows(population,{'fips','year'});
[fips,names] = usstates.states();
data = struct();
for i=1:numel(fips)
    rows = gdp.fips==fips(i);
    d = struct('state',names{i},'fips',fips(i),'year',years(:), ...
        'Y',gdp.Y(rows),'pop',population.pop(rows),'pop_w',population.pop_w(rows));
    d.y_pop = d.Y./d.pop;
    d.y_w = d.Y./d.pop_w;
    data.(matlab.lang.makeValidName(names{i})) = d;
end
usstates.validatePanel(data);
end
