function summaryTbl = Main_USStates(startYear,endYear,dataFile,outDir,makePlots)
% Analyze an explicitly built dataset without network access or clear-all.
root=fileparts(mfilename('fullpath'));
if nargin<1 || isempty(startYear), startYear=1997; end
if nargin<2 || isempty(endYear), endYear=2025; end
if nargin<3 || isempty(dataFile), dataFile=fullfile(root,'data','USStatesData.mat'); end
if nargin<4 || isempty(outDir), outDir=fullfile(root,'output','us_states'); end
if nargin<5, makePlots=true; end
validateattributes(makePlots,{'logical'},{'scalar'});
[data,metadata]=ReadDataUSStates(startYear,endYear,dataFile);
summaryTbl=usstates.summarize(data);
metadata.inputDatasetSHA256=usstates.sha256(dataFile);
metadata.growthDefinition='mean annual log difference, decimal units';
metadata.rankDefinition='descending average ranks for exact ties';
if ~isfolder(outDir), mkdir(outDir); end
writetable(summaryTbl,fullfile(outDir,'USStates_AverageGrowth.csv'));
save(fullfile(outDir,'USStates_AverageGrowth.mat'),'summaryTbl','metadata');
fid=fopen(fullfile(outDir,'USStates_RunMetadata.json'),'w');
assert(fid>=0,'usstates:File','Cannot write run metadata.');
c=onCleanup(@() fclose(fid)); fwrite(fid,jsonencode(metadata),'char'); clear c
if makePlots
    fields=fieldnames(data);
    fig=figure('Visible','off','Color','w','Position',[80 80 1200 500]);
    c=onCleanup(@() close(fig));
    vars={'y_pop','y_w'}; labels={'GDP per capita','GDP per working-age resident'};
    for j=1:2
        subplot(1,2,j); hold on
        for i=1:numel(fields)
            d=data.(fields{i}); plot(d.year,100*d.(vars{j})/d.(vars{j})(1));
        end
        title(sprintf('%s (%d=100)',labels{j},startYear));
        xlabel('Year'); ylabel('Index'); grid on
    end
    saveas(fig,fullfile(outDir,'USStates_IndexPlots.png')); clear c
    fig=figure('Visible','off','Color','w'); c=onCleanup(@() close(fig));
    rp=summaryTbl.rank_g_y_pop; rw=summaryTbl.rank_g_y_w;
    scatter(rp,rw,40,'filled'); hold on; plot([1 50],[1 50],'k--');
    text(rp+0.2,rw,summaryTbl.state,'FontSize',7);
    set(gca,'XDir','reverse','YDir','reverse'); grid on
    xlabel('Rank: mean log growth, GDP per capita');
    ylabel('Rank: mean log growth, GDP per working-age resident');
    title(sprintf('U.S. states, %d-%d',startYear,endYear));
    saveas(fig,fullfile(outDir,'USStates_RankScatter.png')); clear c
    fig=figure('Visible','off','Color','w'); c=onCleanup(@() close(fig));
    histogram(summaryTbl.rank_diff); grid on
    xlabel('Per-capita rank minus working-age rank'); ylabel('Number of states');
    title('Positive difference = better working-age growth rank');
    saveas(fig,fullfile(outDir,'USStates_RankDiffHistogram.png')); clear c
end
fprintf('State analysis complete: %s\n',outDir);
end
