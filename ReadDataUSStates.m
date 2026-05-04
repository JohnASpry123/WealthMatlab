function data = ReadDataUSStates(startYear, endYear, dataFile)
% ReadDataUSStates Load U.S. state panel dataset from MAT file.
%
% data = ReadDataUSStates(startYear, endYear, dataFile)
%
% Inputs
%   startYear (optional): first year to keep (default 1997)
%   endYear   (optional): last year to keep (default inf => all available)
%   dataFile  (optional): path to MAT file (default data/USStatesData.mat)
%
% Output
%   data: struct indexed by state names with fields
%         state, year, Y, pop, pop_w, y_pop, y_w

    if nargin < 1 || isempty(startYear)
        startYear = 1997;
    end
    if nargin < 2 || isempty(endYear)
        endYear = inf;
    end
    if nargin < 3 || isempty(dataFile)
        dataFile = fullfile('data', 'USStatesData.mat');
    end

    if ~isfile(dataFile)
        error(['Dataset file not found: ', dataFile, '. ', ...
               'Run BuildUSStateDataset first to generate it.']);
    end

    S = load(dataFile, 'data');
    data = S.data;

    states = fieldnames(data);
    for i = 1:numel(states)
        st = states{i};
        yrs = data.(st).year;
        keep = yrs >= startYear & yrs <= endYear;

        flds = {'year','Y','pop','pop_w','y_pop','y_w'};
        for j = 1:numel(flds)
            f = flds{j};
            data.(st).(f) = data.(st).(f)(keep);
        end
    end
end
