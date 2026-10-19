function cfg = jwpe_m1_calibration_config(reactor)
%JWPE_M1_CALIBRATION_CONFIG Settings of the accepted fixed-Kd A00 searches.
%   CFG = JWPE_M1_CALIBRATION_CONFIG('CS') or ('PF') only builds settings.
%   Parameter order is [Kd,kb,kG,tinf,Ai]; only columns 2:5 are searched.
%   This is not a PL support extension, an MCMC prior or a new model choice.

reactor = upper(string(reactor));
assert(isscalar(reactor) && any(reactor==["CS","PF"]), ...
    'JWPE:Public:Config','Select exactly one reactor: CS or PF.');
cfg = jwpe_sigma_config();
cfg.version = 'M1_FIXED_KD_CALIBRATION_PUBLIC_CANDIDATE_V2';
cfg.requiredRelease = '2022b';
cfg.analysis = 'calibration_m1_fixed';
cfg.reactor = char(reactor);
cfg.model = 'M1_IRR_SINK';
cfg.temporalLaw = 'NORMALIZED_GOMPERTZ_G1';
cfg.parameterNames = ["Kd","kb","kG","tinf","Ai"];
cfg.parameterUnits = ["L/gTSS","L/(gVSS d)","d^-1","d","1"];
cfg.fixedKd = 0.020;
cfg.freeIndices = 2:5;
cfg.lower = [cfg.fixedKd,0,0.03,10,0];
if reactor=="CS"
    cfg.upper = [cfg.fixedKd,6.25,2,60,0.30];
    cfg.solver = struct('name','ode15s','RelTol',1e-7,'AbsTol',1e-7);
    cfg.rngSeed = 1318722289;
    cfg.initialPointCount = 10;
else
    cfg.upper = [cfg.fixedKd,0.24,2,60,0.30];
    cfg.solver = struct('name','ode15s','RelTol',1e-6,'AbsTol',1e-6);
    cfg.rngSeed = 1058630126;
    cfg.initialPointCount = 8;
end
cfg.rngGenerator = 'twister';
cfg.budget.optimizerCalls = 250;
cfg.budget.recheck = 1;
cfg.budget.rawForwards = 251;
cfg.budget.retries = 0;
cfg.progressEvery = 25;
cfg.recheckToleranceNLL = 5e-4;
cfg.horizon_d = 94;
cfg.phaseCounts = [17,16,0];
cfg.invalid.classification = 'MECHANISTIC_INVALID_NEGATIVE_STATE';
cfg.invalid.threshold = -2e-6;
cfg.invalid.minimumAgreementEpsFactor = 64;
cfg.surrogate.Display = 'off';
cfg.surrogate.UseParallel = false;
cfg.surrogate.UseVectorized = false;
cfg.surrogate.localRefinement = false;
cfg.surrogate.MaxTime = Inf;
cfg.testOnly = false;
end
