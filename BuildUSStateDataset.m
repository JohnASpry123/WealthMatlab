function [data, metadata] = BuildUSStateDataset(startYear, endYear, outFile, cacheDir, offline)
% Build a balanced 50-state panel using pinned Census releases and BEA GDP.
% See README_USStates.md. Defaults are fixed, not the moving current year.
root = fileparts(mfilename('fullpath'));
if nargin<1 || isempty(startYear), startYear=1997; end
if nargin<2 || isempty(endYear), endYear=2025; end
if nargin<3 || isempty(outFile), outFile=fullfile(root,'data','USStatesData.mat'); end
if nargin<4 || isempty(cacheDir), cacheDir=fullfile(root,'data','us_states_raw'); end
if nargin<5, offline=false; end
years=usstates.years(startYear,endYear);
assert(endYear<=2025,'usstates:Vintage','Pinned Census sources end in 2025. Review new vintages explicitly.');
validateattributes(offline,{'logical'},{'scalar'});
population=table(); sources={};
base='https://www2.census.gov/programs-surveys/popest/';
for y=years(years<2000)'
    name=sprintf('stch-icen%d.txt',y);
    url=[base 'tables/1990-2000/intercensal/st-co/' name];
    [file,rec]=usstates.cachedDownload(url,fullfile(cacheDir,name),offline);
    population=[population; usstates.parseCensus(file,'intercensal1990',y)]; %#ok<AGROW>
    sources{end+1}=rec; %#ok<AGROW>
end
spec={2000,2009,'datasets/2000-2010/intercensal/state/st-est00int-agesex.csv','intercensal2000'; ...
      2010,2019,'datasets/2010-2020/state/asrh/SC-EST2020-ALLDATA6.csv','alldata6'; ...
      2020,2025,'datasets/2020-2025/state/asrh/sc-est2025-alldata6.csv','alldata6'};
for i=1:size(spec,1)
    yy=years(years>=spec{i,1} & years<=spec{i,2});
    if isempty(yy), continue; end
    [~,name,ext]=fileparts(spec{i,3});
    [file,rec]=usstates.cachedDownload([base spec{i,3}],fullfile(cacheDir,[name ext]),offline);
    population=[population; usstates.parseCensus(file,spec{i,4},yy)]; %#ok<AGROW>
    sources{end+1}=rec; %#ok<AGROW>
end
% All years included in the BEA request (July 8 correction preserved).
name=sprintf('bea_SAGDP9N_1_%d_%d.json',startYear,endYear);
[file,rec]=usstates.cachedDownload('https://apps.bea.gov/api/data', ...
    fullfile(cacheDir,name),offline,years);
gdp=usstates.parseBEA(jsondecode(fileread(file)),years);
sources{end+1}=rec;
data=usstates.assemble(gdp,population,years);
metadata=struct('schemaVersion',2,'startYear',startYear,'endYear',endYear, ...
    'generatedUTC',char(datetime('now','TimeZone','UTC')), ...
    'gdpUnits','chained 2017 dollars','populationUnits','persons', ...
    'populationUniverse','July 1 resident population','workingAge','15-64 inclusive', ...
    'censusVintagePolicy','1990s intercensal; 2000s intercensal; 2020 vintage for 2010-19; 2025 vintage for 2020-25', ...
    'sources',{sources});
folder=fileparts(outFile);
if ~isempty(folder) && ~isfolder(folder), mkdir(folder); end
save(outFile,'data','metadata');
end
