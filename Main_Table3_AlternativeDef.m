%-------------------------------------------------------------------
% This code replicates the stylized fact (Table 3)
% in Fernandez-Villaverde, Ventura and Yao (2025)
% 
% We use alternative definition of working-age population (15-69).
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

% wa = '15-64'; 
wa = '15-69'; 

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
acronPlot = strrep(acronPlot,"CHN","China");
acronPlot = strrep(acronPlot,"IND","India");

%----------------------------------------------------
% read in data
%----------------------------------------------------
N = size(acron,1);
for indexC = 1:N
    country = acron{indexC};
    if dataSource == 1
        % Read in data from WDI: 1960 to 2022
        dataRaw.(country) =  xlsread('RawData\20240807_WDI.xlsx',country,'A6:T68');
        data.(country) = ReadDataWDI(ySource, dataRaw.(country),wa);
    end
    [~,start]  = min(abs(data.(country).year - startYear));
    [~,finish] = min(abs(data.(country).year - finishYear));
end

varList = {'Y';'y_pop';'pop';'y_w';...
           'pop_w';'pop_w_pop'};

varName = {'GDP';'GDP/Population';'Population';strcat('GDP /(Population ',wa,')');...
           strcat('Population ',wa);strcat('Population ',wa,'/Total Population')};

%----------------------------------------------------
% Table 3: calculate growth rate
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
    excelTable(4,indexC) = mean(growthRate.(country).pop)*100;
    excelTable(5,indexC) = mean(growthRate.(country).pop_w)*100;
    excelTable(6,indexC) = mean(growthRate.(country).pop_w_pop)*100;

    
end

