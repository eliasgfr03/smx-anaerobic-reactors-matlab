function cfg = jwpe_inf_config()
%JWPE_INF_CONFIG Observation-only settings extracted from the shared core.
%
% Historical generic error profiler settings are preserved. The final M1
% deterministic/PL sigma profiler instead uses m1pl_sigma_v3 with the settings
% returned by jwpe_sigma_config. Neither function defines a mechanistic prior
% or launches an outer optimization.

cfg = struct();
cfg.coreVersion = 'JWPE_PUBLIC_OBSERVATION_CORE_v1';
cfg.observation.model = 'combined';
cfg.observation.lod_ug_L = 0.0163;
cfg.observation.zeroTolerance = 0;
cfg.observation.sigmaA_bounds = [1e-6 10.0];
cfg.observation.sigmaP_bounds = [1e-6 10.0];
cfg.observation.profileStarts = [ ...
    0.40 0.25; ...
    0.20 0.40; ...
    0.70 0.12];

cfg.errorProfile.solver = 'fminsearch';
cfg.errorProfile.MaxIterations = 120;
cfg.errorProfile.MaxFunctionEvaluations = 600;
cfg.errorProfile.FunctionTolerance = 1e-10;
cfg.errorProfile.StepTolerance = 1e-10;
cfg.errorProfile.invalidPenalty = 1e12;
cfg.errorProfile.runAllStarts = false;
end
