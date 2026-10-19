function out = m1pl_elig_v3(optimizerNLL,directNLL,sigmas,lower, ...
        upper,exitflag,directTolerance)
%M1PL_ELIG_V3 Evaluate numerical eligibility independently of boundary type.

sigmas = double(sigmas(:).');
lower = double(lower(:).');
upper = double(upper(:).');
assert(numel(sigmas)==2 && numel(lower)==2 && numel(upper)==2 && ...
    isscalar(optimizerNLL) && isscalar(directNLL) && ...
    isscalar(exitflag) && isscalar(directTolerance) && ...
    isfinite(directTolerance) && directTolerance>=0, ...
    'JWPE:M1PL:SigmaEligibility','Invalid eligibility input.');

out = struct();
out.finiteResult = isfinite(optimizerNLL) && isfinite(directNLL) && ...
    all(isfinite(sigmas));
out.withinSupport = all(isfinite(sigmas)) && ...
    all(sigmas>=lower) && all(sigmas<=upper);
out.directDelta = directNLL-optimizerNLL;
out.directAgreement = isfinite(out.directDelta) && ...
    abs(out.directDelta)<=directTolerance;
out.converged = isfinite(exitflag) && exitflag>0;
out.eligible = out.finiteResult && out.withinSupport && ...
    out.directAgreement && out.converged;
out.continuationEligible = out.finiteResult && out.withinSupport && ...
    out.directAgreement && ~out.converged;
if out.eligible
    out.reason = 'ELIGIBLE_CONVERGED';
elseif ~out.finiteResult
    out.reason = 'NONFINITE_RESULT';
elseif ~out.withinSupport
    out.reason = 'OUTSIDE_APPROVED_SUPPORT';
elseif ~out.directAgreement
    out.reason = 'DIRECT_NLL_MISMATCH';
elseif out.continuationEligible
    out.reason = 'ELIGIBLE_FOR_CONTINUATION';
else
    out.reason = 'NOT_ELIGIBLE';
end
end
