function problem = jwpe_oem_problem(inputs)
%JWPE_OEM_PROBLEM Scientific historical adapter; computes ONE anchor forward.
cfg = inputs.cfg;
data = inputs.data;
settings = inputs.settings;
hardMax = cfg.public.rawForwardHardMax;
ledger = jwpe_oem_budget('create',struct(),hardMax);
[simulateCached,getCacheStats,clearCache] = ...
    JWPE_OEM_make_cached_simulator_v1_3(@local_raw,cfg.cache.maxEntries);
anchorEngine = cfg.anchorHistoricalEngine.(inputs.reactor);
anchorNative = JWPE_OEM_engine_to_native_v1_3(anchorEngine);
anchorSimulation = simulateCached(anchorNative);
problem = struct('reactor',inputs.reactor,'data',data,'settings',settings, ...
    'simulate',simulateCached,'simulateRaw',@local_raw, ...
    'getCacheStats',getCacheStats,'clearCache',clearCache, ...
    'getRawBudget',@local_budget,'nObs',inputs.nObs, ...
    'isCensored',inputs.isCensored,'isQuantified',inputs.isQuantified, ...
    'nCensored',inputs.nCensored,'lod_ug_L',cfg.lod.ug_L, ...
    'reference',struct('anchorEngine',anchorEngine(:).', ...
    'anchorNative',anchorNative(:).','anchorSimulation',anchorSimulation));

    function sim = local_raw(thetaNative)
        ledger = jwpe_oem_budget('begin',ledger,hardMax);
        try
            thetaEngine = JWPE_OEM_native_to_engine_v1_3(thetaNative);
            if strcmp(inputs.reactor,'CS')
                sim = CS_simulate_model(thetaEngine,data,settings,data.Time_d,false);
            else
                sim = PF_simulate_model(thetaEngine,data,settings,data.Time_d,false);
            end
            ledger = jwpe_oem_budget('complete',ledger,hardMax);
        catch ME
            ledger = jwpe_oem_budget('fail',ledger,hardMax);
            rethrow(ME)
        end
    end

    function current = local_budget()
        current = ledger;
    end
end
