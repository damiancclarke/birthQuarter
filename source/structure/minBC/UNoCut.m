function [U] = UNoCut(age)
% Calculates utility of not cutting based on the age of the timber
% stand. The function returns U, the utility.

U = log(age+1);

end