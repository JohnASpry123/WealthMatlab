function years = years(first, last)
% Explicit, contiguous annual sample; never silently shorten it.
validateattributes(first, {'numeric'}, {'scalar','real','finite','integer','>=',1997});
validateattributes(last, {'numeric'}, {'scalar','real','finite','integer','>=',first});
years = (first:last)';
end
