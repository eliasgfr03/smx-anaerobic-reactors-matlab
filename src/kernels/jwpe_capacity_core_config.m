function cfg = jwpe_capacity_core_config()
%JWPE_INF_CONFIG Shared inference configuration for JWPE-D-26-03371.
%
% PURPOSE
%   Centralize the numerical/statistical settings that are common to future
%   deterministic calibration, profile likelihood (PL), and MCMC wrappers.
%   The validated mechanistic engines are intentionally NOT configured here;
%   they remain authoritative in Shared_model_engine/MATLAB.
%
%   Mean parameters (native scientific coordinates):
%       [Kd, kb, krev, kG, tinf, Ai]
%   Observation model used for inference:
%       sigma_i^2 = sigmaA^2 + (sigmaP*yhat_i)^2
%   Stored experimental zeros mean y < LOD and enter the likelihood as
%   left-censored observations at LOD = 0.0163 ug/L.
%
% DESIGN RULE
%   Observation-error parameters never enter the mechanistic forward model.
%   Future optimization/PL code should therefore profile or otherwise update
%   sigmaA/sigmaP without re-running CS_simulate_model/PF_simulate_model.
%
% SAFE MODIFICATIONS
%   Stage-specific solver budgets/progress cadence may be overridden by the
%   calling stage. Do NOT change LOD semantics, parameter mapping, or the
%   historical diagnostic support without a new scientific decision.

cfg = struct();
cfg.coreVersion = 'JWPE_INFERENCE_CORE_v1_0_2026-08-18';
cfg.project = 'JWPE-D-26-03371';
cfg.date = '2026-08-18';

cfg.observation.model = 'combined';
cfg.observation.lod_ug_L = 0.0163;
cfg.observation.zeroTolerance = 0;
cfg.observation.sigmaA_bounds = [1e-6 10.0];   % ug/L
cfg.observation.sigmaP_bounds = [1e-6 10.0];   % dimensionless

% Deterministic inner starts for profiling [sigmaA sigmaP]. These are
% observation-only starts: changing them never triggers a mechanistic forward.
cfg.observation.profileStarts = [ ...
    0.40 0.25; ...
    0.20 0.40; ...
    0.70 0.12];

%% Native mean-parameter coordinates
cfg.mean.paramNames = {'Kd','kb','krev','kG','tinf','Ai'};
cfg.mean.paramUnits = {'L/gTSS','L/(gVSS d)','L/(gVSS d)','1/d','d','-'};

% This remains a DIAGNOSTIC/COMPUTATIONAL support inherited from the
% historical identifiability work; it is not promoted to a final physical
% bound or MCMC prior by this core.
cfg.mean.bounds = [ ...
    0.000 0.060; ...       % Kd
    0.255 6.250; ...       % kb
    0.000 0.9375; ...      % krev
    0.030 2.000; ...       % kG
    10.0  60.0; ...        % tinf
    0.000 0.300];          % Ai
cfg.mean.historicalSupport.kSigma = [0.30 6.25];
cfg.mean.historicalSupport.Fdir = [0.85 1.00];

%% Exact forward cache
cfg.cache.enabled = true;
cfg.cache.maxEntries = 128;

%% Observation-error profiling (cheap inner optimization; no ODE calls)
% fminsearch is deliberately used for the 1-2D inner nuisance problem. It is
% derivative-free and avoids nesting fmincon inside the outer fmincon used by
% future deterministic calibration/PL. Bounds are enforced in log-space by a
% deterministic penalty; accepted optima are far from the broad supports.
cfg.errorProfile.solver = 'fminsearch';
cfg.errorProfile.MaxIterations = 120;
cfg.errorProfile.MaxFunctionEvaluations = 600;
cfg.errorProfile.FunctionTolerance = 1e-10;
cfg.errorProfile.StepTolerance = 1e-10;
cfg.errorProfile.invalidPenalty = 1e12;
% can set runAllStarts=true to verify that this does not hide an inner basin.
cfg.errorProfile.runAllStarts = false;

%% Generic outer optimizer defaults
% Stage wrappers may override these. The core deliberately does not assume
% that every PL point needs a central-difference polish; that decision belongs
% to the PL protocol after benchmark/validation.
cfg.optimizer.algorithm = 'sqp';
cfg.optimizer.searchFiniteDifferenceType = 'forward';
cfg.optimizer.polishFiniteDifferenceType = 'central';
cfg.optimizer.searchMaxIterations = 140;
cfg.optimizer.polishMaxIterations = 50;
cfg.optimizer.FunctionTolerance = 1e-8;
cfg.optimizer.StepTolerance = 1e-8;
cfg.optimizer.OptimalityTolerance = 1e-7;
cfg.optimizer.ConstraintTolerance = 1e-10;
cfg.optimizer.UseParallel = false;
cfg.optimizer.searchMaxFunctionEvaluations.CS = 1400;
cfg.optimizer.searchMaxFunctionEvaluations.PF = 1200;
cfg.optimizer.polishMaxFunctionEvaluations.CS = 1200;
cfg.optimizer.polishMaxFunctionEvaluations.PF = 1200;
cfg.optimizer.invalidObjectivePenalty = 1e12;

% Finite-difference steps are in normalized native mean coordinates only.
% sigmaA/sigmaP are profiled internally and therefore are NOT outer finite-
% difference coordinates.
cfg.optimizer.fdStepNormalizedMean = [3e-3 1e-3 1e-3 1e-3 3e-4 3e-4]';

%% Numerical QA
cfg.quality.mappingRoundTripTolerance = 1e-12;
cfg.quality.predictionReferenceTolerance = 1e-5;
cfg.quality.nllReferenceTolerance = 5e-4;
cfg.quality.errorParameterRelativeTolerance = 1e-2;
cfg.quality.minimumStateTolerance = -1e-8;
cfg.quality.nativeFeasibilityTolerance = 1e-9;

%% Progress and reproducible outputs
cfg.progress.enabled = true;
cfg.progress.printEveryIterations = 2;
cfg.progress.printForwardCounterEvery = 25;

cfg.output.pngResolution = 600;
cfg.output.writeCSV = true;
cfg.output.writeExcel = true;
cfg.output.writeMAT = true;
cfg.output.saveRawAndDerived = true;
end
