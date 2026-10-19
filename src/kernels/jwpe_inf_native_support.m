function [isFeasible,detail] = jwpe_inf_native_support(theta,cfg)
%JWPE_INF_NATIVE_SUPPORT Check the inherited native diagnostic support.
%
% This function deliberately labels the domain as diagnostic/computational.
% Passing this test does NOT mean the bounds are final physical bounds or
% Bayesian priors.

theta = theta(:);
assert(numel(theta)==6,'Expected six native mean parameters.');

tol = cfg.quality.nativeFeasibilityTolerance;
bounds = cfg.mean.bounds;
insideBox = all(theta>=bounds(:,1)-tol & theta<=bounds(:,2)+tol);

try
    [~,derived] = jwpe_inf_native_to_engine(theta);
    ks = cfg.mean.historicalSupport.kSigma;
    fd = cfg.mean.historicalSupport.Fdir;
    kSigmaPass = derived.kSigma>=ks(1)-tol && derived.kSigma<=ks(2)+tol;
    FdirPass = derived.Fdir>=fd(1)-tol && derived.Fdir<=fd(2)+tol;
catch
    derived = struct('kSigma',NaN,'Fdir',NaN);
    kSigmaPass = false;
    FdirPass = false;
end

isFeasible = insideBox && kSigmaPass && FdirPass;
detail = struct('insideBox',insideBox,'kSigmaPass',kSigmaPass, ...
    'FdirPass',FdirPass,'kSigma',derived.kSigma,'Fdir',derived.Fdir);
end
