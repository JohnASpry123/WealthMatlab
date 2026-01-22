%-------------------------------------------------------------------
% This code replicates the stylized fact (Table 2)
% in Fernandez-Villaverde, Ventura and Yao (2025)
% 
% We decompose the growth of GDP for the G7 countries.
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

varList = {'Y';'pop';'a';...
            'e';'h';'y_tilde';...
            'y_e';'y_w';...
            'H';'pop_w';'H_pop_w'};
varName = {'GDP';'Population';'Working-age per Person';...
           'Employment Rate of Working-age';'Hours Worked per Worker';'GDP per Hour Worked';...
           'GDP per Worker';'GDP per Working-age Adult';...
           'Total Hours Worked';'Working-age Population';'Hours Worked per Working-age'};

%----------------------------------------------------
% Table 2: calculate growth rate
%----------------------------------------------------
for indexC = 1:N

    country = acron{indexC};
    for i = 1:size(varList,1)
        variable = varList{i};
        growthRate.(country).(variable) = growth(data.(country).(variable)(start:finish));

    end
        
    excelTable(1,indexC) = mean(growthRate.(country).Y)*100;
    excelTable(2,indexC) = mean(growthRate.(country).pop)*100;
    excelTable(3,indexC) = mean(growthRate.(country).a)*100;
    excelTable(4,indexC) = mean(growthRate.(country).e)*100;
    excelTable(5,indexC) = mean(growthRate.(country).h)*100;
    excelTable(6,indexC) = mean(growthRate.(country).y_tilde)*100;
    excelTable(7,indexC) = mean(growthRate.(country).y_e)*100;
    excelTable(8,indexC) = mean(growthRate.(country).y_w)*100;
    excelTable(9,indexC) = mean(growthRate.(country).H)*100;
    excelTable(10,indexC) = mean(growthRate.(country).pop_w)*100;
    excelTable(11,indexC) = mean(growthRate.(country).H_pop_w)*100;

end

