function country = ReadDataWDI(ySource, data, wa)
    
    country.year = data(:,1);
    
    if ySource == 1
        country.Y   = data(:,2); % 1: constant 2015 US$
    elseif ySource == 2
        country.Y   = data(:,3); % 2: constant local currency unit
    elseif ySource == 3
        country.Y   = data(:,4); % 3: constant 2017 international$    
    end

    % back out employment    
    country.Y_PPP   = data(:,4);   % GDP constant 2017 international$    
    country.y_PPP_e = data(:,10);  % GDP per person employed (constant 2017 international$)
    country.emp = country.Y_PPP./country.y_PPP_e; % person employed

    country.pop       = data(:,5); % population
    country.pop_15_64 = data(:,6); % 15-64 working age population

    country.pop_15_19_FR = data(:,13); % 15-19 female to total female population ratio
    country.pop_15_19_MR = data(:,14); % 15-19 male to total male population ratio
    country.pop_20_24_FR = data(:,15); % 20-24 female to total female population ratio
    country.pop_20_24_MR = data(:,16); % 20-24 male to total male population ratio
    country.pop_65_69_FR = data(:,17); % 65-69 female to total female population ratio
    country.pop_65_69_MR = data(:,18); % 65-69 male to total male population ratio

    country.pop_F =  data(:,19); % total female population
    country.pop_M =  data(:,20); % total male population

    country.pop_15_19 = (country.pop_15_19_FR.*country.pop_F + country.pop_15_19_MR.*country.pop_M)/100;
    country.pop_20_24 = (country.pop_20_24_FR.*country.pop_F + country.pop_20_24_MR.*country.pop_M)/100;
    country.pop_65_69 = (country.pop_65_69_FR.*country.pop_F + country.pop_65_69_MR.*country.pop_M)/100;

    % working-age population
    switch wa
        case '15-64'
            country.pop_w = country.pop_15_64;
        case '15-69'
            country.pop_w = country.pop_15_64 + country.pop_65_69;
    end


    % convert into per capita term     
    country.y_pop = country.Y./country.pop; 
    country.y_w   = country.Y./country.pop_w;
    country.y_e   = country.Y./country.emp;

    % pop_w_pop: working-age adult per person
    country.pop_w_pop = country.pop_w./country.pop;
    % employment per person
    country.emp_pop = country.emp./country.pop;
 
end
