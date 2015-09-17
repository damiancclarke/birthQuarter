% simBirths.m v0.00             damiancclarke              yyyy-mm-dd:2015-09-17
%---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
%
% Simulate wage and birth offers to make birth decisions.
%
clear
clc

%-------------------------------------------------------------------------------
%---(1) Simulate and preset
%-------------------------------------------------------------------------------
N     = 1000;
T     = 5;
educ  = randi(2,N,1)-1;
RetEd = [2,1];
GoodS = [1,0,1,0];

Wages = NaN(N,T,2);
Quali = NaN(N,T);
exper = 0;
Gamma = 0.1;

%-------------------------------------------------------------------------------
%---(2) Calculate wages and quality based on simulated values
%-------------------------------------------------------------------------------
for t=1:T
    Wages(:,t,1)=2+RetEd(2)*educ+0.5*exper;
    exper = exper+1;
    Wages(:,t,2)=4+RetEd(1)*educ+0.5*exper;
    if t<5
        Quali(:,t)=3000 + 100*educ + 20*GoodS(t) - 40*exper;
    end
end

%-------------------------------------------------------------------------------
%---(3) Calculate utility based on simulated values
%-------------------------------------------------------------------------------
Utility = NaN(N,T,2);
Utility(:,:,1) = Wages(:,:,1) + randn(N,T);


for t=1:T
        betas          = 0.95.^(1:T-t+1) 
        Utility(:,t,2) = Wages(:,t:T,1)*transpose(betas) + ...
                         Gamma*Quali(:,t) + randn(N,1);
end


%-------------------------------------------------------------------------------
%---(4) Value Function
%-------------------------------------------------------------------------------
