function [value,choice] = ValFunc(state,age,VF1,BETA)
% Returns the value function based on the value of the state
% variable, the age of the timber stand, the value function in the
% future, and the discount rate BETA.  Returns value and choice.
% Value is the value of the optimal choice, and choice is the
% optimal choice (cut=1 or not cut=0).

R0 = UNoCut(age);
R1 = UCut(age,state);

[value,choice]=max([R0+BETA*VF1,R1],[],2);
choice = choice - 1;

end