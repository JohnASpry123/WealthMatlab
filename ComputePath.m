function residual = ComputePath(k,para)

    global T solver
    
    beta   = para.beta;
    sigma  = para.sigma;
    delta  = para.delta;
    g      = para.g;
    theta  = para.theta;
    nPath  = para.nPath;
    lPath  = para.lPath;
    kss1   = para.kss1;
    kss2   = para.kss2;    
    
    % size of k path: T+1
    % size of c path: T-1
    % size of ee path: T-1
    
    beta_s = beta*(1+g)^(1-sigma);
    
    residual = ones(T+1,1);
    c  = ones(T-1,1);
    ee = ones(T-1,1);
    
    for t = 1:T-1
        
        c(t)   = (1-delta)*k(t) + lPath(t)^(1-theta)*k(t)^theta - (1+g)*(1+nPath(t+1))*k(t+1);
        c(t+1) = (1-delta)*k(t+1) + lPath(t+1)^(1-theta)*k(t+1)^theta - (1+g)*(1+nPath(t+2))*k(t+2);       
        residual(t) = c(t)^(-sigma)*(1+g) - beta_s*c(t+1)^(-sigma)*( theta*lPath(t+1)^(1-theta)*k(t+1)^(theta-1) + 1-delta );
        
        ee(t) = 1- (beta_s*( theta*lPath(t+1)^(1-theta)*k(t+1)^(theta-1) +  1-delta )/(1+g))^(-1/sigma)*c(t+1)/c(t); % euler equation error

    end

    residual(T) = k(1)   - kss1;
    residual(T+1) = k(T+1) - kss2;
    
    solver.residual = residual;
    solver.cPath    = c;
    solver.eePath   = ee;

end

  

