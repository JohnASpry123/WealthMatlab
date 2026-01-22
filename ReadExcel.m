function country = ReadExcel(acronName)

    %-----------------------------------------------------
    % read in a specific country's data
    %-----------------------------------------------------  
    [~, ~, table] = xlsread('data\20230817_WDI_G7.xlsx', acronName);  
    
    %-------------------------------------------------------------------------
    %                    1          2           3      4    5                6      
    % data sequence: [year, Y_constUS, Y_constLCU, Y_PPP, pop, working-age pop  
    %-------------------------------------------------------------------------
    raw = table(6:end,:); % remove the first five lines
    data = cell2mat(raw);

    country.year       = data(:,1);
    country.Y_constUS  = data(:,2);
    country.Y_constLCU = data(:,3);
    country.Y_PPP      = data(:,4);
    country.pop        = data(:,5);
    country.L          = data(:,6);
   
    % country.y = country.Y./country.pop;    
    country.l = country.L./country.pop;
    
end