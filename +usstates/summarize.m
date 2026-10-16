function result = summarize(data)
years = usstates.validatePanel(data);
assert(numel(years)>=2,'usstates:Sample','At least two annual observations required.');
[fips,names] = usstates.states();
g = zeros(50,5);
variables = {'Y','y_pop','y_w','pop','pop_w'};
for i=1:50
    d = data.(matlab.lang.makeValidName(names{i}));
    for j=1:5
        g(i,j) = mean(usstates.logGrowth(d.(variables{j})));
    end
end
rp = usstates.rankDescending(g(:,2)); rw = usstates.rankDescending(g(:,3));
result = table(names,fips,repmat(years(1),50,1),repmat(years(end),50,1), ...
    repmat(numel(years)-1,50,1),g(:,1),g(:,2),g(:,3),g(:,4),g(:,5),rp,rw,rp-rw, ...
    'VariableNames',{'state','fips','start_year','end_year','n_intervals', ...
    'g_Y','g_y_pop','g_y_w','g_pop','g_pop_w','rank_g_y_pop','rank_g_y_w','rank_diff'});
% Names break display-order ties only; tied numerical ranks stay equal.
result = sortrows(result,{'rank_g_y_pop','state'});
end
