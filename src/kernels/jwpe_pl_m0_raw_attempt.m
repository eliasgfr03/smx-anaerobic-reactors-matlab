function [sim,ledger] = jwpe_pl_m0_raw_attempt(ledger,simulate,nObs,minTol,recheck,onProgress)
%JWPE_PL_M0_RAW_ATTEMPT Guard source simulator without changing trial policy.
% Finite negative-state SEARCH returns are rejected by the source evaluator.
% Exceptions, nonfinite/malformed returns and invalid raw rechecks STOP.
cap=ledger.hardMax;
assert(~ledger.pending && ledger.rawFailed==0,'JWPE:Public:Budget', ...
    'Previous raw attempt failed or remains uncertain; no automatic retry.');
ledger=jwpe_oem_budget('begin',ledger,cap);
try
    onProgress(ledger);
    sim=simulate();
    assert(isstruct(sim) && isscalar(sim) && ...
        all(isfield(sim,{'prediction_ug_L','min_SMX','min_TP'})), ...
        'JWPE:PL:Model','Malformed simulator return.');
    pred=sim.prediction_ug_L;
    assert(isnumeric(pred) && isreal(pred) && isvector(pred) && numel(pred)==nObs ...
        && all(isfinite(pred(:))) && isnumeric(sim.min_SMX) && isscalar(sim.min_SMX) ...
        && isreal(sim.min_SMX) && isfinite(sim.min_SMX) ...
        && isnumeric(sim.min_TP) && isscalar(sim.min_TP) && isreal(sim.min_TP) ...
        && isfinite(sim.min_TP),'JWPE:PL:Model','Malformed or nonfinite raw return.');
    rejected=sim.min_SMX<minTol || sim.min_TP<minTol;
    assert(~recheck || ~rejected,'JWPE:PL:Recheck','Invalid independent recheck.');
    ledger=jwpe_oem_budget('complete',ledger,cap);
    onProgress(ledger);
catch ME
    if ledger.pending; ledger=jwpe_oem_budget('fail',ledger,cap); end
    onProgress(ledger);
    error('JWPE:Public:Budget','PL execution stopped: %s | %s',ME.identifier,ME.message);
end
end
