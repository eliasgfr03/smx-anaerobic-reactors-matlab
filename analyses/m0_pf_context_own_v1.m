function [ctx,core] = m0_pf_context_own_v1(b,cfg,onProgress)
%PF_PL_CONTEXT Source PF hydraulics and 145 d forcing, 33 I-II observations.
% Construction creates handles only. The current ledger is read by closure.
core=b.core; data=b.forcing; times=b.observations.Time_d;
obs=b.observations.Cout_ug_L; settings=b.settings;
assert(all(isnan(data.Cout_ug_L)) && numel(obs)==33 && max(times)==94);
cap=cfg.totalNewObjectiveCap+1;
ledger=jwpe_oem_budget('create',struct(),cap);
[simulate,cacheStats,clearCache]=jwpe_inf_make_forward_cache(@(theta)raw(theta,false),core.cache.maxEntries);
ctx=struct('reactor','PF','dataForcing',data,'settings',settings, ...
    'calibrationTimes_d',times,'calibrationObserved_ug_L',obs,'nCalibrationObs',33, ...
    'nCalibrationCensored',0,'fitEndDay',94,'integrationEndDay',145, ...
    'G1',struct('simulate',simulate,'simulateRaw',@(theta)raw(theta,true), ...
    'getCacheStats',cacheStats,'clearCache',clearCache),'getRawLedger',@getLedger);
    function current=getLedger()
        current=ledger;
    end
    function sim=raw(theta,recheck)
        assert(ledger.rawAttempts<cap-double(~recheck),'JWPE:Public:Budget', ...
            'PF cap reached; the raw independent recheck is reserved.');
        integrate=@()PF_simulate_model(jwpe_inf_native_to_engine(theta),data,settings,times,false);
        [sim,ledger]=jwpe_pl_m0_raw_attempt(ledger,integrate,33, ...
            core.quality.minimumStateTolerance,recheck,@record);
    end
    function record(current)
        ledger=current;
        onProgress(current);
    end
end
