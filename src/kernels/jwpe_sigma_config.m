function cfg = jwpe_sigma_config()
%JWPE_SIGMA_CONFIG Supply the exact likelihood contract for m1pl_sigma_v3.
%
% Error scales are profiled using a supplied prediction vector. This function
% only constructs settings; it evaluates neither a model nor a likelihood.

scfg = m1pl_sb_cfg_v3();
cfg = struct();
cfg.likelihood.model = scfg.likelihoodModel;
cfg.likelihood.lod_ug_L = scfg.lod_ug_L;
cfg.likelihood.sigmaLower = scfg.sigmaLower;
cfg.likelihood.sigmaUpper = scfg.sigmaUpper;
cfg.likelihood.baseStarts = scfg.baseStarts;
cfg.likelihood.runAllStarts = scfg.runAllStarts;
cfg.likelihood.MaxIter = scfg.blockMaxIterations;
cfg.likelihood.MaxFunEvals = scfg.blockMaxFunctionEvaluations;
cfg.likelihood.TolFun = scfg.functionTolerance;
cfg.likelihood.TolX = scfg.stepTolerance;
cfg.likelihood.directTolerance = scfg.directTolerance;
cfg.likelihood.supportBoundaryFraction = scfg.supportBoundaryFraction;
end
