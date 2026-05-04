function g = growth(x)
% growth Compute log-difference growth rates.
%
% g_t = log(x_t) - log(x_{t-1})

    g = log(x(2:end)) - log(x(1:end-1));
end
