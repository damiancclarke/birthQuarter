function [points,vals] = genInt(sigma)
% Function to generate quadrature points for integrating error term
% based on a normally distributed variable with standard deviation
% sigma.  The only argument is sigma.  Returns points and vals,
% where vals are weighting values, and points are weight points.
%
% Uses an anonymous function normdcc which is a normal.  This has
% been tested by integration.
%
% Requires on the function lgwt which creates the Gauss-Legendre
% weights for the integral

normdcc = @(x) 1/(sigma*sqrt(2*pi))*exp((-(x-0).^2)/(2*sigma^2));
%Q = integral(normdcc,-1.96,1.96);
%zeropoint = normdcc(0);

[points,vals] = lgwt(5,-3*sigma,3*sigma);
points = normdcc(points);
%points'*vals

end
