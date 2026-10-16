%-------------------------------------------------------------------
% This code replicates the simulation results (Figure 5.1 and Table 5) 
% in Fernandez-Villaverde, Ventura and Yao (2025)
%
% This program computes a one-sector growth model with exogenous 
% technology growth rate and working-age to total population rate.
%
% Author: Wen Yao
% Date: 09/2023
%-------------------------------------------------------------------


% clc
clear all
close all

global ss T solver

tstart = tic; % timer

country = 'USA';
% country = 'CAN';
% country = 'FRA';
% country = 'DEU';
% country = 'ITA';
% country = 'JPN';
% country = 'ESP';
% country = 'GBR';

start  = 1991;
finish = 2019;

constLN = 0; % 0: time varying working-age/pop
             % 1: constant working-age/pop (sample mean) 

growthTFP = 0; % 0: use GDP per working-age or per capita growth rate as growth rate
               % 1: use TFP growth rate from PWT as growth rate

constLS = 1; % 0: use country-specific labor share
             % 1: use constant labor share from the U.S. for all 

%--------------------------------------------
% 0. Length of transition
%-------------------------------------------- 
T = finish - start; 

%-------------------------------------------------
% 1. Read Data and set country-specific parameters
%------------------------------------------------- 
ReadData

if constLN == 1 % constant LFP rate (sample mean) 
    l = mean(l)*ones(T+1,1);
end

%---------------------------------------
% 2. 1991 Parameters
%---------------------------------------
sigma    = 1;      % set risk aversion
delta    = 0.04;
beta     = (1+0.0163)/(1+0.077); % use growth rate of GDP per capita in the U.S.

if constLS == 0
    theta = 1- mean(labsh)
elseif constLS == 1
    theta = 0.39
end

if growthTFP == 0
    g        = mean(growth(YL)) % baseline model: growth rate of GDP per working-age in each country
    % g        = mean(growth(YN)) % canonical model: growth rate of GDP per capita in each country
%     g        = 0.0178  % 1981-2019 growth rate of GDP per working-age in the U.S.
%     g        = 0.0165  % 1991-2019 growth rate of GDP per working-age in the U.S.
elseif growthTFP == 1
    g        = mean(growth(TFP.^(1/(1-theta)))) % growth rate of TFP from PWT 10.0
    excelTFP = [mean(growth(YL))*100, mean(growth(TFP))*100,g*100,theta]'; 
end

n_0 = n(1);    % population growth in initial steady state
n_T = n(end);  % population growth in final steady state
l_0 = l(1);    % LFP in initial steady state
l_T = l(end);  % LFP in final steady state

%---------------------------------------
% 3. Steady State
%---------------------------------------
% initial steady state
clear para
para.theta = theta;
para.beta  = beta;
para.sigma = sigma;
para.delta = delta;
para.g     = g;
para.n     = n_0;
para.l     = l_0;
x = fsolve(@(x) SteadyState(x,para),0.5);
ss1 = ss

% final steady state
clear para
para.theta = theta;
para.beta  = beta;
para.sigma = sigma;
para.delta = delta;
para.g     = g;
para.n     = n_T;
para.l     = l_T;
x = fsolve(@(x) SteadyState(x,para),0.5);
ss2 = ss

%-----------------------------------------------
% 5. Solve country X's transitional path 
%-----------------------------------------------
% use linear line between k0 and kss as guess
x0 = linspace(ss1.k, ss2.k, T+1)';             

clear para
para.beta   = beta;
para.sigma  = sigma;
para.delta  = delta;
para.g      = g;
para.theta  = theta;
para.nPath  = n;
para.lPath  = l;
para.kss1   = ss1.k;
para.kss2   = ss2.k;
options = optimoptions('fsolve','Display','iter');
[kPath,residual,exitflag,output] = fsolve(@(x)ComputePath(x,para),x0,options);
cPath  = solver.cPath;
eePath = solver.eePath;

%-----------------------------------------------
% compute other variables of interest
%-----------------------------------------------
yPath     = zeros(T+1,1);
iPath     = zeros(T,1);
IYPath    = zeros(T,1);
rPath     = zeros(T+1,1);
YNPath    = zeros(T+1,1);
YLPath    = zeros(T+1,1);
KNPath    = zeros(T+1,1);
KYPath    = zeros(T+1,1);
APath     = zeros(T+1,1);

A_0 = YN(1)/ss1.y;

time = 1:1:T+1;
for t = 1:T+1
    yPath(t)  = l(t)^(1-theta)*kPath(t)^theta; 
    
    if t<T+1
        iPath(t)  = kPath(t+1)*(1+g)*(1+n(t+1)) - (1-delta)*kPath(t);
        IYPath(t) = iPath(t)/yPath(t);
    end

    rPath(t)  = theta*(l(t))^(1-theta)*kPath(t)^(theta-1) - delta; % return to capital
    APath(t) = A_0*(1+g)^(t-1); % first period A_t = A_0. 

    YNPath(t)    = yPath(t)*APath(t);    % income per capita
    YLPath(t)    = YNPath(t)./l(t);      % income per working capita
    KNPath(t)    = kPath(t)*APath(t);    % capital per capita
    KYPath(t)    = kPath(t)./yPath(t);   % K/Y ratio

end

disp('check convergence')
ss2.k % final steady state capital
kPath(T+1) % last period capial

% computing time
tfinish = toc(tstart);
disp(strcat('seconds taken: ',num2str(tfinish)))

%--------------------------------------------
% 7. Plot Transitional Path
%--------------------------------------------            
PlotPaper
       
%--------------------------------------------
% 8. MSE between model and the data
%--------------------------------------------   
dataT = size(YL,1);

% income per capita
MSE_YN = sum((YNPath./YNPath(1) - YN./YN(1)).^2)/dataT % in level
% income per working-age
MSE_YL = sum((YLPath./YLPath(1) - YL./YL(1)).^2)/dataT % in level

excelData = [MSE_YN; MSE_YL]
