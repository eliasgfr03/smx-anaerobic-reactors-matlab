function A = jwpe_03b_log2_activity_v1(t,kA,t50)
%JWPE_03B_LOG2_ACTIVITY_V1 Stable normalized logistic acclimation capacity.
%
%   A(t) = 1/(1 + exp(-kA*(t-t50)))
%
% A numerically stable branch avoids overflow for large |kA*(t-t50)|.
% The output has the same shape as t and satisfies 0<A<1 for finite inputs.

validateattributes(kA,{'numeric'},{'scalar','real','finite','positive'},mfilename,'kA');
validateattributes(t50,{'numeric'},{'scalar','real','finite'},mfilename,'t50');
z = kA.*(double(t)-t50);
A = zeros(size(z));
pos = z>=0;
A(pos) = 1./(1+exp(-z(pos)));
ez = exp(z(~pos));
A(~pos) = ez./(1+ez);
end
