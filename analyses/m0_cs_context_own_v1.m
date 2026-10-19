function [ctx,core] = m0_cs_context_own_v1(b,caseConfig,onProgress)
%JWPE_PL_M0_CONTEXT Native CS forcing through 145 d, 33 I-II responses only.
% Construction reads inputs and creates handles, executing no simulation.
% Raw attempts, including failures, are counted BEFORE integration.
assert(isscalar(caseConfig) && isstruct(caseConfig),'JWPE:PL:Config','Invalid case.');
assert(isa(onProgress,'function_handle'),'JWPE:PL:Config','Missing ledger callback.');
core=b.core; data=b.forcing; observed=b.observations.Cout_ug_L;
calTimes=b.observations.Time_d; settings=b.settings; f='EXPLICIT_INPUT';
cat=b.catalogue;
assert(all(isnan(data.Cout_ug_L)) && numel(observed)==33 && max(calTimes)==94);
cap=caseConfig.config.maxFunctionEvaluations+1;
ledger=jwpe_oem_budget('create',struct(),cap);
[simulate,getStats,clearCache]=jwpe_inf_make_forward_cache( ...
    @(theta)raw(theta,false),core.cache.maxEntries);
ctx=struct('reactor','CS','dataFile',f,'dataForcing',data,'settings',settings, ...
    'calibrationTimes_d',calTimes,'calibrationObserved_ug_L',observed, ...
    'nCalibrationObs',33,'nCalibrationCensored',0,'thetaRef',cat.anchor.theta(:).', ...
    'fitEndDay',94,'integrationEndDay',145,'G1',struct('simulate',simulate, ...
    'simulateRaw',@(theta)raw(theta,true),'getCacheStats',getStats, ...
    'clearCache',clearCache),'getRawLedger',@getLedger);

    function current=getLedger()
        % Read the shared current state; do not capture an initial value.
        current=ledger;
    end

    function sim=raw(theta,recheck)
        attemptCap=cap-double(~recheck);
        assert(ledger.rawAttempts<attemptCap,'JWPE:Public:Budget', ...
            'Conditional search cap reached; one raw recheck is reserved.');
        integrate=@()CS_simulate_model(jwpe_inf_native_to_engine(theta), ...
            data,settings,calTimes,false);
        [sim,ledger]=jwpe_pl_m0_raw_attempt(ledger,integrate,33, ...
            core.quality.minimumStateTolerance,recheck,@record);
    end
    function record(current)
        ledger=current;
        onProgress(ledger);
    end
end
