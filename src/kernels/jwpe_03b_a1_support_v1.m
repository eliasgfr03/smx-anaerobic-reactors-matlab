function [isFeasible,detail] = jwpe_03b_a1_support_v1(x,cfgCore)
%JWPE_03B_A1_SUPPORT_V1 Support check for the no-adaptation null model.
%
% Only [Kd,kb,krev] are estimable. The same diagnostic/computational support
% used by the Inference Core is enforced for these coordinates and for the
% derived [kSigma,Fdir]. Ai=1 is deliberately outside the adaptive-model Ai
% support because it defines a different structural hypothesis, not a G1 fit.

x = double(x(:));
assert(numel(x)==3,'Expected [Kd,kb,krev].');
tol = cfgCore.quality.nativeFeasibilityTolerance;
bounds = cfgCore.mean.bounds(1:3,:);
insideBox = all(x>=bounds(:,1)-tol & x<=bounds(:,2)+tol);

try
    kb = x(2); krev = x(3); kSigma = kb+krev; Fdir = kb/kSigma;
    ks = cfgCore.mean.historicalSupport.kSigma;
    fd = cfgCore.mean.historicalSupport.Fdir;
    kSigmaPass = kSigma>=ks(1)-tol && kSigma<=ks(2)+tol;
    FdirPass = Fdir>=fd(1)-tol && Fdir<=fd(2)+tol;
catch
    kSigma = NaN; Fdir = NaN; kSigmaPass = false; FdirPass = false;
end
isFeasible = insideBox && kSigmaPass && FdirPass;
detail = struct('insideBox',insideBox,'kSigmaPass',kSigmaPass, ...
    'FdirPass',FdirPass,'kSigma',kSigma,'Fdir',Fdir);
end
