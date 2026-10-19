function [sim,ledger] = jwpe_capacity_raw_attempt(ledger,cap,simulate,nObs,minTol,recheck,onProgress)
%JWPE_CAPACITY_RAW_ATTEMPT Account one returned trial without accepting it.
% Finite, correctly shaped returns with negative states are completed raw
% attempts, not execution failures. The unchanged evaluator rejects them.
% Rechecks, malformed returns, exceptions and budget failures remain fatal.
assert(isa(simulate,'function_handle') && isa(onProgress,'function_handle'), ...
    'JWPE:Capacity:Inputs','Invalid raw-attempt callback.');
assert(~ledger.pending && ledger.rawFailed==0 && ledger.rawAttempts<cap, ...
    'JWPE:Public:Budget','Temporal forward cap or failure reached.');
if ~isfield(ledger,'rawRejectedState'); ledger.rawRejectedState=0; end
if ~isfield(ledger,'lastStateRejection'); ledger.lastStateRejection=[]; end
ledger=jwpe_oem_budget('begin',ledger,51);
try
    onProgress(ledger);
    sim=simulate();
    assert(isstruct(sim) && isscalar(sim) && ...
        all(isfield(sim,{'prediction_ug_L','min_SMX','min_TP'})), ...
        'JWPE:Capacity:Model','Malformed temporal simulator schema.');
    pred=sim.prediction_ug_L;
    assert(isnumeric(pred) && isreal(pred) && isvector(pred) && ...
        numel(pred)==nObs && all(isfinite(pred(:))) && ...
        isnumeric(sim.min_SMX) && isreal(sim.min_SMX) && isscalar(sim.min_SMX) && ...
        isfinite(sim.min_SMX) && isnumeric(sim.min_TP) && isreal(sim.min_TP) && ...
        isscalar(sim.min_TP) && isfinite(sim.min_TP), ...
        'JWPE:Capacity:Model','Malformed or nonfinite temporal simulator return.');
    rejected=sim.min_SMX<minTol || sim.min_TP<minTol;
    if rejected
        ledger.rawRejectedState=ledger.rawRejectedState+1;
        ledger.lastStateRejection=struct('rawAttempt',ledger.rawAttempts, ...
            'minSMX',sim.min_SMX,'minTP',sim.min_TP,'minimumStateTolerance',minTol);
        assert(~recheck,'JWPE:Capacity:Recheck','Invalid independent raw recheck.');
    end
    ledger=jwpe_oem_budget('complete',ledger,51);
    onProgress(ledger);
catch ME
    if ledger.pending; ledger=jwpe_oem_budget('fail',ledger,51); end
    onProgress(ledger);
    error('JWPE:Public:Budget','Temporal execution aborted: %s | %s', ...
        ME.identifier,ME.message);
end
end
