function [value,choice] = ValFunc(state,age,VF1,BETA,grid,SS)
% Returns the value function based on the value of the state
% variable, the age of the timber stand, the value function in the
% future, and the discount rate BETA.  The argument 'grid' must
% also be passed to indicate which state value each part of the
% value function refers to.  Returns value and choice. Value is the
% value of the optimal choice, and choice is the optimal choice
% (cut=1 or not cut=0).

%----------------------------------------------------------------------
%--- (1) grid over expected state in next period using Gauss-Legendre
%----------------------------------------------------------------------
%%MUST CALCULATE EXPECTED VALUE FUNCTION BY:
%%(a) CALCULATE GAUSS-LEGENDRE WEIGHTS BASED ON SIGMA (add as
%%argument)
%%(b) TAKE VALUE FUNCTION BASED ON ARRIVING WITH CURRENT STATE, BUT
%%ADDING DIFFERENT VALUES DUE TO SHOCK.
%%(c) ALSO DO THE SAME THING FOR DISTRIBUTION OF STATE VARIABLE
%[epspoints,epsweights] = genInt(ES,'normal');
[stapoints,staweights] = genInt(SS,'unifor');

Xnext    = repmat(state,1,5)+1+repmat(stapoints',length(state),1);
position = round(Xnext*10+1);
position(position>401)=401;
EVF = sum(VF1(position),2)/5;


R0 = UNoCut(age);
R1 = UCut(age,state);


[value,choice]=max([R0+BETA*EVF,R1],[],2);
choice = choice - 1;

end
