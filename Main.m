%-------------------------------------------------------------------
% Replication pipeline for U.S. states (Fernandez-Villaverde, Ventura,
% and Yao, 2025), 1997 onward.
%
% This script:
%   1) Builds/loads a reproducible state-level dataset
%   2) Computes log-difference growth rates
%   3) Outputs a table of average growth rates by state
%   4) Produces index plots (1997=100)
%   5) Produces rank scatter and rank-difference histogram
%-------------------------------------------------------------------

clear; close all; clc;

startYear = 1997;
endYear = year(datetime('today')) - 1;
dataFile = fullfile('data', 'USStatesData.mat');
outDir = 'output';

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

if ~isfile(dataFile)
    fprintf('Dataset not found. Building from BEA + Census APIs...\n');
    BuildUSStateDataset(startYear, endYear, dataFile);
end

data = ReadDataUSStates(startYear, endYear, dataFile);
states = fieldnames(data);
N = numel(states);

% Containers
stateName = strings(N,1);
g_Y = nan(N,1);
g_y_pop = nan(N,1);
g_y_w = nan(N,1);
g_pop = nan(N,1);
g_pop_w = nan(N,1);

for i = 1:N
    st = states{i};
    D = data.(st);

    stateName(i) = string(D.state);
    g_Y(i) = mean(growth(D.Y), 'omitnan');
    g_y_pop(i) = mean(growth(D.y_pop), 'omitnan');
    g_y_w(i) = mean(growth(D.y_w), 'omitnan');
    g_pop(i) = mean(growth(D.pop), 'omitnan');
    g_pop_w(i) = mean(growth(D.pop_w), 'omitnan');
end

% Rank diagnostics
[~, orderPop] = sort(g_y_pop, 'descend');
[~, orderW] = sort(g_y_w, 'descend');
rankPop = nan(N,1); rankW = nan(N,1);
rankPop(orderPop) = 1:N;
rankW(orderW) = 1:N;
rankDiff = rankPop - rankW;

summaryTbl = table(stateName, g_Y, g_y_pop, g_y_w, g_pop, g_pop_w, rankPop, rankW, rankDiff, ...
    'VariableNames', {'state','g_Y','g_y_pop','g_y_w','g_pop','g_pop_w','rank_g_y_pop','rank_g_y_w','rank_diff'});
summaryTbl = sortrows(summaryTbl, 'g_y_pop', 'descend');

disp(summaryTbl);
writetable(summaryTbl, fullfile(outDir, 'USStates_AverageGrowth.csv'));
save(fullfile(outDir, 'USStates_AverageGrowth.mat'), 'summaryTbl');

% -------------------------
% Plot 1: index plots 1997=100
% -------------------------
fig1 = figure('Color','w','Position',[80 80 1200 500]);

subplot(1,2,1); hold on;
for i = 1:N
    st = states{i};
    D = data.(st);
    idx = 100 * D.y_pop ./ D.y_pop(1);
    plot(D.year, idx, 'LineWidth', 0.8);
end
title('GDP per capita index (1997=100)');
xlabel('Year'); ylabel('Index'); grid on;

subplot(1,2,2); hold on;
for i = 1:N
    st = states{i};
    D = data.(st);
    idx = 100 * D.y_w ./ D.y_w(1);
    plot(D.year, idx, 'LineWidth', 0.8);
end
title('GDP per working-age adult index (1997=100)');
xlabel('Year'); ylabel('Index'); grid on;

saveas(fig1, fullfile(outDir, 'USStates_IndexPlots.png'));

% -------------------------
% Plot 2: rank scatter
% -------------------------
fig2 = figure('Color','w');
scatter(rankPop, rankW, 40, 'filled'); hold on;
plot([1 N], [1 N], 'k--', 'LineWidth', 1);
text(rankPop + 0.2, rankW, cellstr(stateName), 'FontSize', 7);
set(gca, 'YDir', 'reverse');
set(gca, 'XDir', 'reverse');
grid on;
xlabel('Rank of avg growth in GDP per capita (g_{y\_pop})');
ylabel('Rank of avg growth in GDP per working-age (g_{y\_w})');
title('Rank scatter across U.S. states');
saveas(fig2, fullfile(outDir, 'USStates_RankScatter.png'));

% -------------------------
% Plot 3: histogram rank differences
% -------------------------
fig3 = figure('Color','w');
histogram(rankDiff);
grid on;
xlabel('Rank difference: rank(g_{y\_pop}) - rank(g_{y\_w})');
ylabel('Number of states');
title('Histogram of rank differences');
saveas(fig3, fullfile(outDir, 'USStates_RankDiffHistogram.png'));

fprintf('Pipeline complete. Outputs written to %s\n', outDir);
