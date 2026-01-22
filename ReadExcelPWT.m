function country = ReadExcelPWT(acronName,constLS)

    %-----------------------------------------------------
    % read in a specific country's data
    %-----------------------------------------------------  
    if constLS == 0
        [~, ~, table] = xlsread(strcat('data\PWT100_',acronName,'.xlsx'));  
    elseif constLS == 1
        [~, ~, table] = xlsread(strcat('data\PWT100_',acronName,'constLS','.xlsx'));  
    end 

    %----------------------------------------------------------------------------------
    %                    1        2    3                4            5       6      7
    % data sequence: [year, rgdp_na, pop, working-age pop, labor share, rtfpna, rk_na 
    %----------------------------------------------------------------------------------
    raw = table(2:end,3:end); % read numbers only
    data = cell2mat(raw);

    country.year   = data(:,1);
    country.rgdpna = data(:,2)*10^6; % in millions
    country.pop    = data(:,3);
    country.L      = data(:,4);
    country.labsh  = data(:,5);
    country.rtfpna = data(:,6);
    country.rkna   = data(:,7);
   
    % country.y = country.Y./country.pop;    
    country.l = country.L./country.pop;
    
end