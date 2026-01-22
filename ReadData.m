
%-----------------------------------------------------
% read in country X's data
%----------------------------------------------------- 
if growthTFP == 0
    dataX = ReadExcel(country);
elseif growthTFP == 1
    dataX = ReadExcelPWT(country,constLS);
end

%-----------------------------------------------------
% process the data
%----------------------------------------------------- 
[~,startIndex] = min(abs(dataX.year - start));
[~,finishIndex] = min(abs(dataX.year - finish));

year = dataX.year(startIndex:finishIndex); 
pop  = dataX.pop(startIndex:finishIndex); % total population
L    = dataX.L(startIndex:finishIndex);   % working-age population
l    = dataX.l(startIndex:finishIndex);   % labor force participation


if growthTFP == 0
    Y    = dataX.Y_constLCU(startIndex:finishIndex); 
elseif growthTFP == 1
    Y    = dataX.rgdpna(startIndex:finishIndex); 
    TFP  = dataX.rtfpna(startIndex:finishIndex); 
    labsh = dataX.labsh(startIndex:finishIndex);
end

YN = Y./pop; % income per capita
YL = Y./L;   % income per working-age 

%----------------------------------------------------- 
% population growth rate
%----------------------------------------------------- 
if (startIndex > 1) && ~isnan(dataX.pop(startIndex-1))
    n  = growth(dataX.pop(startIndex-1:finishIndex));
else
    n  = growth(dataX.pop(startIndex:finishIndex)); 
    n  = [n(1); n]; 
end
