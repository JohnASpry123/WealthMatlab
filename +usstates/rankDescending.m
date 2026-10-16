function ranks = rankDescending(values)
% Average ranks for exact ties, highest growth = rank 1; no toolbox needed.
validateattributes(values, {'numeric'}, {'vector','real','finite','nonempty'});
[ordered, index] = sort(values(:), 'descend');
ranks = zeros(size(ordered));
first = 1;
while first <= numel(ordered)
    last = first;
    while last < numel(ordered) && ordered(last+1) == ordered(first)
        last = last + 1;
    end
    ranks(index(first:last)) = (first+last)/2;
    first = last + 1;
end
end
