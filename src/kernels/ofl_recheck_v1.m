function result = ofl_recheck_v1(best,repeated,cfg)
%OFL_RECHECK_V1 Pure decision; caller persists before asserting PASS.
result=struct();
result.sameKb=isequal(best.kb,repeated.kb);
result.deltaNLL=repeated.fit.nll-best.fit.nll;
result.directDelta=repeated.fit.directRecalculationDelta;
result.rawClass=best.fit.classification;
result.recheckClass=repeated.fit.classification;
result.pass=best.valid && repeated.valid && result.sameKb && ...
    isfinite(result.deltaNLL) && abs(result.deltaNLL)<=cfg.likelihood.recheck_NLL_tolerance && ...
    isfinite(result.directDelta) && abs(result.directDelta)<=cfg.likelihood.direct_NLL_tolerance;
result.status='RECHECK_REVIEW_REQUIRED';
if result.pass, result.status='INDEPENDENT_RAW_RECHECK_PASS'; end
end
