% simBirths.m v0.00             damiancclarke              yyyy-mm-dd:2015-09-17
%---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
%
% Simulate wage and birth offers to make birth decisions.
%
% Here, Utility(:,:,2) is having birth and Utility(:,:,1) is
% remaining childless.  As such, RetEd[c,b] has return for chidless (c)
% women and women who have had a birth (b).

clear
clc
%rng(2727)
%-------------------------------------------------------------------------------
%---(1a) Simulate and preset
%-------------------------------------------------------------------------------
N     = 1000;
T     = 5;
educ  = randi(2,N,1)-1;
GoodS = [1,0,1,0];

Wages = NaN(N,T,2);
Quali = NaN(N,T);
exper = 0;
Gamma = 0.01;
BETA  = 0.2;

%-------------------------------------------------------------------------------
%---(1b) Coefficients
%-------------------------------------------------------------------------------
RetEd  = [3,1];
RetEx  = [1,1];
RetEx2 = [0.5,0.01];
WageC  = [10,2];

BwEd   = 100;
BwEx   = 40;
BwGood = 10;
BwCoef = 2800;

%-------------------------------------------------------------------------------
%---(2) Calculate wages and quality based on simulated values
%-------------------------------------------------------------------------------
%WAGES: Childless
Wages(:,1,1) = 1000 + 400*educ;
Wages(:,2,1) = 1000 + 800*educ + 200;
Wages(:,3,1) = 1000 + 1600*educ + 600; 
Wages(:,4,1) = 1000 + 2000*educ + 1000;
Wages(:,5,1) = 1000 + 2000*educ + 1000;

%WAGES: Birth
Wages(:,1,2) = 800 + 300*educ;
Wages(:,2,2) = 800 + 600*educ + 100;
Wages(:,3,2) = 800 + 1200*educ + 300;
Wages(:,4,2) = 800 + 1500*educ + 500;
Wages(:,5,2) = 800 + 1500*educ + 500;

%Quality
Quali(:,1) = 300 + 100 + 100*educ;
Quali(:,2) = 300 + 100*educ;
Quali(:,3) = 300 + 50  + 50*educ;
Quali(:,4) = 300 + 50*educ;


%for t=1:T
%    Wages(:,t,1)=WageC(2)+RetEd(2)*educ+RetEx(2)*exper+RetEx2(2)*exper^2;
%    exper = exper+1;
%    Wages(:,t,2)=WageC(1)+RetEd(1)*educ+RetEx(1)*exper+RetEx2(1)*exper^2;
%    if t<5
%        Quali(:,t)=2800 + BwEd*educ + BwGood*GoodS(t) - BwEx*exper;
%    end
%end

%-------------------------------------------------------------------------------
%---(3) Calculate utility based on simulated values
%-------------------------------------------------------------------------------
Utility = NaN(N,T,2);
Utility(:,:,1) = log(Wages(:,:,1)) + randn(N,T);


for t=1:T
    betas          = BETA.^(1:T-t+1) 
    Utility(:,t,2) = log(Wages(:,t:T,1))*transpose(betas) + ...
        Gamma*log(Quali(:,t)) + randn(N,1);
end

%-------------------------------------------------------------------------------
%---(4) Value Function
%-------------------------------------------------------------------------------
VF      = NaN(N,T);
VF(:,5) = 0;

for t=(T-1):-1:1
    fprintf('Time Period: %d\n', t)

    VF(:,t) = max(Utility(:,t,1) + BETA*VF(:,t+1), Utility(:,t,2))
end

[VFv,birthTime] = max(VF,[],2)
[sum(birthTime==1) sum(birthTime==2) sum(birthTime==3) sum(birthTime==4)]
