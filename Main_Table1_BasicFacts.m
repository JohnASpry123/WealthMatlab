%-------------------------------------------------------------------
% This code replicates the stylized fact (Table 1 and Figure 2.1)
% in Fernandez-Villaverde, Ventura and Yao (2025)
% 
% We compute the GDP per capita and GDP per working 
% age population for the G7 countries.
%
% Author: Wen Yao
% Date: 09/2023
%-------------------------------------------------------------------
clear all;
close all;
clc

%----------------------------------------------------
% set parameters
%----------------------------------------------------

dataSource = 1; % 1: WDI
                % 2: IMF
                % 3: PWT

ySource = 2; % 1: WDI constant 2015 US$
             % 2: WDI constant local currency unit
             % 3: WDI constant 2017 international$

constH = 0; % 1: constant hours
            % 0: time-varying hours

startYear  = 1991;
finishYear = 2019;

acron = {'CAN';'FRA';'DEU';'ITA';'JPN';'ESP';'GBR';'USA'};
% acron = {'CHN';'IND'};
acron = string(acron);

acronPlot = acron;
acronPlot = strrep(acronPlot,"USA","U.S.");
acronPlot = strrep(acronPlot,"CAN","Canada");
acronPlot = strrep(acronPlot,"FRA","France");
acronPlot = strrep(acronPlot,"DEU","Germany");
acronPlot = strrep(acronPlot,"ITA","Italy");
acronPlot = strrep(acronPlot,"JPN","Japan");
acronPlot = strrep(acronPlot,"ESP","Spain");
acronPlot = strrep(acronPlot,"GBR","UK");


%----------------------------------------------------
% read in data
%----------------------------------------------------
N = size(acron,1);
for indexC = 1:N
    country = acron{indexC};
    if dataSource == 1
        % Read in data from WDI: 1960 to 2022
        dataRaw.(country) =  xlsread('RawData\20240807_WDI.xlsx',country,'A6:L68');
        data.(country) = ReadDataWDI_PWT(ySource, constH, dataRaw.(country));
    end
    [~,start]  = min(abs(data.(country).year - startYear));
    [~,finish] = min(abs(data.(country).year - finishYear));
end

varList = {'Y';'y_pop';'y_w';'y_tilde';'y_e';...
           'pop';'pop_w';'H'};
       
varName = {'GDP';'GDP per capita';'GDP per Working-age Adult';'GDP per Hour Worked';'GDP per Worker';...
           'Population';'Working-age Population';'Total Hours Worked'};
       
%----------------------------------------------------
% Table 1: calculate growth rate
%----------------------------------------------------
for indexC = 1:N

    country = acron{indexC};
    for i = 1:size(varList,1)
        variable = varList{i};
        growthRate.(country).(variable) = growth(data.(country).(variable)(start:finish));

    end
        
    excelTable(1,indexC) = mean(growthRate.(country).Y)*100;
    excelTable(2,indexC) = mean(growthRate.(country).y_pop)*100;
    excelTable(3,indexC) = mean(growthRate.(country).y_w)*100;
    excelTable(4,indexC) = mean(growthRate.(country).y_tilde)*100;
    excelTable(5,indexC) = mean(growthRate.(country).y_e)*100;
    excelTable(6,indexC) = mean(growthRate.(country).pop)*100;
    excelTable(7,indexC) = mean(growthRate.(country).pop_w)*100;
    excelTable(8,indexC) = mean(growthRate.(country).H)*100;
    
end


%----------------------------------------------------
% Figure 2.1: calculate index 
%----------------------------------------------------
for indexC = 1:N

    country = acron{indexC};

    for i = 1:size(varList,1)
        variable = varList{i};
        index.(country).(variable) = data.(country).(variable)(start:finish)/data.(country).(variable)(start)*100;
        Table(:,i) = index.(country).(variable);
    end
    
end

%----------------------------------------------------
% Figure 2.1: plot 
%----------------------------------------------------
time = startYear:1:finishYear; 

for indexC = 1:N
    country = acron{indexC};
    switch country
        case {'USA','JPN'}
            LineType.(country) = '-.';
        case {'IND'}
            LineType.(country) = ':';
        otherwise
            LineType.(country) = '-';
    end
end

for i = 1:size(varList,1)
    variable = varList{i};
    switch variable
        case {'a'}
            LegendLoc.(variable) = 'SouthWest';
        otherwise
            LegendLoc.(variable) = 'NorthWest';
    end
end

for i = 1:size(varList,1)
    variable = varList{i};
    figure
    for indexC = 1:N
        country = acron{indexC};
        plot(time,index.(country).(variable),LineType.(country),'LineWidth',2)
        hold on
    end
    xlim([time(1) time(end)])
    legend(acronPlot,'Location',LegendLoc.(variable))
    title([varName{i} ' Index  (' num2str(startYear) '=100)'])
end