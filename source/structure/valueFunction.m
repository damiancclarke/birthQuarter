function VF = valueFunction(parameters,UBirth,UNoBirth,EV)
% parameters are a vector = [beta, sd normal]
% UBirth is utility of birth in current period
% UNoBirth is utility of no birth in current period
% EV is expected value function in future.  parameters =
% {BETA,SIGMA}


rng(1);
BETA  = parameters(1);
SIGMA = parameters(2);

%-------------------------------------------------------------------------------
%--- (1) calculate values of shock for expected value function
%-------------------------------------------------------------------------------
draws = 50000;
VF    = 0;
for i = 1:draws
    VF = VF + (1/draws)*max(UNoBirth+BETA*EV+SIGMA*randn(), UBirth);
end

