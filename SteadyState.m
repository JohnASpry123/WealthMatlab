function residual = SteadyState(k,para)

    global ss 
    
    % these are country specific parameters
    theta  = para.theta;
    beta   = para.beta;
    sigma  = para.sigma;
    delta  = para.delta;
    g      = para.g;
    n      = para.n;
    l      = para.l;
    
    beta_s = beta*((1+g))^(1-sigma);
    
    residual(1,1) = beta_s*( l^(1-theta)*theta*k^(theta-1) + 1-delta ) - (1+g);    
    
    y = k^theta*l^(1-theta);
    i = (1+g)*(1+n)*k - (1-delta)*k;
    c = y - i;
    rk = l^(1-theta)*theta*k^(theta-1) - delta;
 
    ss.k = k;
    ss.c = c;
    ss.y = y;
    ss.i = i;
    ss.iy = i/y;
    ss.ky = k/y;
    ss.rk = rk;
end

  

