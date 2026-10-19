function u = jwpe_opt_normalize(x,lb,ub)
%JWPE_OPT_NORMALIZE Map physical parameters to normalized [0,1] coordinates.
%
% Scientific bounds remain explicit in the calling stage. Normalization is
% purely numerical and does not create new physical information or priors.

[x,lb,ub] = local_rows(x,lb,ub);
span = ub-lb;
assert(all(isfinite(span) & span>0), ...
    'All optimization variables require finite, nonzero physical bounds.');
u = (x-lb)./span;
end

function [x,lb,ub] = local_rows(x,lb,ub)
lb = lb(:).'; ub = ub(:).';
assert(numel(lb)==numel(ub),'Lower/upper bound sizes differ.');
assert(size(x,2)==numel(lb), ...
    'Parameter matrix column count does not match bounds.');
end
