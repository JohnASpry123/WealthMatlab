function country = ReadDataWDI_PWT(ySource, constH, data)
    
    country.year = data(:,1);
    
    if ySource == 1
        country.Y = data(:,2); % 1: constant 2015 US$
    elseif ySource == 2
        country.Y = data(:,3); % 2: constant local currency unit
    elseif ySource == 3
        country.Y = data(:,4); % 3: constant 2017 international$    
    end

    % back out employment    
    country.Y_PPP   = data(:,4);   % GDP constant 2017 international$    
    country.y_PPP_e = data(:,10);  % GDP per person employed (constant 2017 international$)
    country.emp = country.Y_PPP./country.y_PPP_e; % person employed

    country.pop   = data(:,5); % population
    country.pop_w = data(:,6); % working age population


    country.y_pop = country.Y./country.pop;   % GDP per person
    country.y_e   = country.Y./country.emp;   % GDP per worker 
    country.y_w   = country.Y./country.pop_w; % GDP per working-age 

    if constH == 1
        % h: hours worked per worker, assume constant here
        country.h = ones(size(country.Y,1),1);
    else
        % Average annual hours worked by persons engaged
        country.h = data(:,12); % avh from PWT10.0
    end

    % a: working-age adult per person
    country.a = country.pop_w./country.pop;
    % e: employment rate of working-age adult
    country.e = country.emp./country.pop_w;
    % H: total hours of working-age adult
    country.H = country.h.*country.emp;
    % y_tilde: output per hour worked
    country.y_tilde = country.Y./country.H;

    % employment per person
    country.emp_pop = country.emp./country.pop;
    
    % hours per working-age
    country.H_pop_w = country.H./country.pop_w;
    

end
