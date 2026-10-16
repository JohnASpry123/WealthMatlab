function checkGrid(t, years, variables)
% Require exactly one valid observation for each state/year.
[f, y] = ndgrid(usstates.states(), years);
expected = sortrows([f(:),y(:)]);
assert(height(t) == size(expected,1) && ...
    isequal(sortrows([t.fips,t.year]), expected), ...
    'usstates:Coverage', 'Expected exactly one row for all 50 states in every requested year; missing or duplicate keys.');
for i = 1:numel(variables)
    x = t.(variables{i});
    assert(isnumeric(x) && isreal(x) && all(isfinite(x) & x > 0), ...
        'usstates:Values', 'Nonpositive, nonfinite or suppressed values in %s.', variables{i});
end
end
