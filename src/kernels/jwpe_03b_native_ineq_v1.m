function c = jwpe_03b_native_ineq_v1(x,cfgCore)
%
% Returns c<=0 inequalities matching the Inference Core historical
% computational support for kSigma=kb+krev and Fdir=kb/kSigma. Box bounds are
% already enforced separately by the master optimizer.

x = double(x(:).');
assert(numel(x)>=3,'At least [Kd,kb,krev] are required.');
kb=x(2); krev=x(3); kSigma=kb+krev;
if ~(isfinite(kSigma) && kSigma>0)
    c = [1 1 1 1];
    return
end
Fdir=kb/kSigma;
ks=cfgCore.mean.historicalSupport.kSigma;
fd=cfgCore.mean.historicalSupport.Fdir;
c = [ks(1)-kSigma, kSigma-ks(2), fd(1)-Fdir, Fdir-fd(2)];
end
