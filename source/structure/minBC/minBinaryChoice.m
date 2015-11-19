% Optimal stopping code dynamic model example.  Uses example from
% forestry paper.
%
% Subroutines: UNoCut: calculates R0
%              UCut  : calculates R1
%              VF    : calculates Value Function

%-------------------------------------------------------------------------------
%--- Hardcoded parameters
%-------------------------------------------------------------------------------
N = 100;
T = 10;
X = NaN(N,T);
X(:,1) = 0;
BETA = 0.9;

%-------------------------------------------------------------------------------
%--- State variable
%-------------------------------------------------------------------------------
for i = 2:T
   X(:,i) = X(:,i-1) + 1 + 3*rand(N,1);
end

%-------------------------------------------------------------------------------
%--- Utilities
%-------------------------------------------------------------------------------
R0 = UNoCut(repmat((1:10),[N,1]));
R1 = UCut(repmat((1:10),[N,1]),X);

%-------------------------------------------------------------------------------
%--- Value Function
%--- We want a value function of T+1 periods (VF_{T+1} = 0), where
%--- it is based on the state value grided over 'grid' units.
%-------------------------------------------------------------------------------
statemin    = 0;
statedif    = 0.1;
statemax    = 30;
grid        = [statemin:statedif:statemax]';
VF      = [NaN(length(grid),T),zeros(length(grid),1)];
choices = [NaN(length(grid),T)];

for t = T:-1:1
    [VF(:,t), choices(:,t)]=ValFunc(grid,t*ones(length(grid),1),VF(:,t+1),BETA);
end


%-------------------------------------------------------------------------------
%--- Simulate choices
%-------------------------------------------------------------------------------
position = round(X*10+1);

obsgrowth = NaN(N,T);
obschoice = NaN(N,T);

for t=1:T
    for p=1:N
        if t==1
            obschoice(p,t) = choices(round(X(p,t)*10+1),t);
            obsgrowth(p,t) = X(p,t);
        elseif t>1
            if obschoice(p,t-1)==0
                obschoice(p,t) = choices(round(X(p,t)*10+1),t);
                obsgrowth(p,t) = X(p,t);
            end
        end
    end
end