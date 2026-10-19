function ledger = jwpe_oem_budget(action,ledger,hardMax)
%JWPE_OEM_BUDGET Pure raw-attempt accounting; never invokes a model or target.
assert(isscalar(hardMax) && isfinite(hardMax) && hardMax>=1 && ...
    hardMax==floor(hardMax),'JWPE:Public:Budget','Invalid raw-forward limit.');
switch lower(string(action))
    case "create"
        ledger = struct('rawAttempts',0,'rawCompleted',0,'rawFailed',0, ...
            'pending',false,'hardMax',hardMax);
    case "begin"
        assert(~ledger.pending && ledger.hardMax==hardMax && ...
            ledger.rawAttempts<hardMax,'JWPE:Public:Budget', ...
            'Raw-forward budget exhausted or an uncertain attempt remains.');
        ledger.rawAttempts = ledger.rawAttempts+1;
        ledger.pending = true;
    case "complete"
        assert(ledger.pending,'JWPE:Public:Budget','No pending raw attempt.');
        ledger.rawCompleted = ledger.rawCompleted+1;
        ledger.pending = false;
    case "fail"
        assert(ledger.pending,'JWPE:Public:Budget','No pending raw attempt.');
        ledger.rawFailed = ledger.rawFailed+1;
        ledger.pending = false;
    otherwise
        error('JWPE:Public:Budget','Unknown raw-budget action.');
end
end
