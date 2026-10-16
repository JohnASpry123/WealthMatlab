function text = yearList(years)
% Preserve July 8 fix: BEA requires every year, not just endpoints.
assert(isequal(years(:), usstates.years(years(1), years(end))), ...
    'usstates:Years', 'Years must be a contiguous annual vector.');
text = sprintf('%d,', years);
text = text(1:end-1);
end
