function cfg = jwpe_opt_master_config(nvar)
%
% PURPOSE
%   Return the single optimization policy approved for JWPE revised-version
%   analyses that genuinely require numerical optimization. Scientific stage
%   code should call this function instead of recreating solver options.
%
% POLICY
%   - normalized coordinates are always [0,1]^nvar;
%   - standard hard budget is 50 objective/mechanistic evaluations;
%   - no automatic local polish, multistart, second optimizer, or extension;
%   - one independent best-point recheck is QA, not another optimization.
%
% IMPORTANT
%   This function defines project policy, not a universal MathWorks default.
%   The values below were selected from the 2026-08-18 project microbenchmarks
%   and are frozen until an explicitly approved project-level change.

validateattributes(nvar,{'numeric'},{'scalar','integer','positive','finite'}, ...
    mfilename,'nvar');

cfg = struct();
cfg.version = 'JWPE_OPTIMIZATION_CORE_v1_0_1';
cfg.solver = 'surrogateopt';
cfg.seed = 20260818;
cfg.maxFunctionEvaluations = 50;
cfg.minSurrogatePoints = max(8,nvar+1);
cfg.display = 'iter';
cfg.useParallel = false;
cfg.useVectorized = false;
cfg.invalidObjectivePenalty = 1e12;
% Recheck compares the fast profiled-NLL evaluation against an independent
% raw-forward + robust all-starts error-profile evaluation. Small numerical
% differences are expected from nuisance-parameter profiling. Use the same
% NLL reference tolerance already validated by JWPE_INFERENCE_CORE_v1_0.
cfg.recheckAbsoluteTolerance = 5e-4;
cfg.pngResolution = 600;
cfg.checkpointPolicy = 'expensive_only';
cfg.validationMode = false;
cfg.allowNonstandardBudget = false;
cfg.nvar = nvar;

assert(cfg.minSurrogatePoints <= cfg.maxFunctionEvaluations, ...
    ['The frozen 50-forward budget is incompatible with this problem ' ...
     'dimension. Discuss the problem formulation/budget before running.']);
end
