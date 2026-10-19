function out = jwpe_pl_m0_eval(x,caseConfig,ctx,core,recheck)
%JWPE_PL_M0_EVAL Thin native adapter to the unchanged G1 error profiler.
try
    theta=jwpe_pl_m0_map(x,caseConfig);
    out=jwpe_03b_evaluate_g1_v1(theta,ctx,core,recheck,recheck);
    if out.rawForwardIncrement>0
        assert(isfinite(out.nll) && isfield(out.errorFit,'sigmaA') ...
            && isfield(out.errorFit,'sigmaP') && isfinite(out.errorFit.sigmaA) ...
            && isfinite(out.errorFit.sigmaP),'JWPE:PL:Score','Nonfinite error profile.');
    end
    assert(~recheck || out.valid,'JWPE:PL:Recheck','Invalid independent endpoint.');
catch ME
    % The shared master must not convert fatal failures into its trial penalty.
    error('JWPE:Public:Budget','PL evaluation stopped: %s | %s',ME.identifier,ME.message);
end
end
