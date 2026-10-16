function [data, metadata] = ReadDataUSStates(startYear, endYear, dataFile)
% Offline-only loader. An insufficient or legacy cache is an error.
if nargin<1 || isempty(startYear), startYear=1997; end
if nargin<2 || isempty(endYear), endYear=inf; end
if nargin<3 || isempty(dataFile)
    dataFile=fullfile(fileparts(mfilename('fullpath')),'data','USStatesData.mat');
end
assert(isfile(dataFile),'usstates:File','Run BuildUSStateDataset first; missing %s.',dataFile);
s=load(dataFile,'data','metadata');
assert(isfield(s,'data') && isfield(s,'metadata') && ...
    isfield(s.metadata,'schemaVersion') && s.metadata.schemaVersion==2, ...
    'usstates:Schema','Legacy/unversioned dataset: rebuild to correct GDP units and population definitions.');
data=s.data; metadata=s.metadata;
available=usstates.validatePanel(data);
assert(metadata.startYear==available(1) && metadata.endYear==available(end) && ...
    strcmp(metadata.gdpUnits,'chained 2017 dollars') && strcmp(metadata.workingAge,'15-64 inclusive'), ...
    'usstates:Metadata','Dataset metadata does not match its contents.');
if isequal(endYear,inf), endYear=available(end); end
requested=usstates.years(startYear,endYear);
assert(all(ismember(requested,available)), 'usstates:Coverage', ...
    'Requested sample is not fully covered. Rebuild explicitly; no silent truncation.');
keep=ismember(available,requested);
fields=fieldnames(data); variables={'year','Y','pop','pop_w','y_pop','y_w'};
for i=1:numel(fields)
    for j=1:numel(variables)
        data.(fields{i}).(variables{j})=data.(fields{i}).(variables{j})(keep);
    end
end
usstates.validatePanel(data);
metadata.analysisStartYear=startYear; metadata.analysisEndYear=endYear;
end
