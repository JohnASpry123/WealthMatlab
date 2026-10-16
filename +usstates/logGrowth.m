function g = logGrowth(x)
% State extension only. The original growth.m retains simple returns.
validateattributes(x, {'numeric'}, {'vector','real','finite','positive','numel',numel(x)});
assert(numel(x) >= 2, 'usstates:Sample', 'Growth needs at least two annual observations.');
g = diff(log(x(:)));
end
