function [U] = UCut(age,volume)
% Calculates the utility of not cutting based on the age of the
% timber and the volume of the timber.  Returns U, the utility.

lambda = 4;
U = log(age+1) + 1*volume + lambda;

end