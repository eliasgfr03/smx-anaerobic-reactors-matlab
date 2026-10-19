function x = jwpe_opt_denormalize(u,lb,ub)
%JWPE_OPT_DENORMALIZE Map normalized coordinates back to physical values.

lb = lb(:).'; ub = ub(:).';
assert(numel(lb)==numel(ub),'Lower/upper bound sizes differ.');
assert(size(u,2)==numel(lb), ...
    'Normalized parameter matrix column count does not match bounds.');
span = ub-lb;
assert(all(isfinite(span) & span>0), ...
    'All optimization variables require finite, nonzero physical bounds.');
x = lb + u.*span;
end
