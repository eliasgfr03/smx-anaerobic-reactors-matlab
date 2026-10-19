function scfg = m1pl_sb_cfg_v3()
%M1PL_SB_CFG_V3 Numerical settings needed by the final M1 sigma profiler.
%
% Extracted without changing starts, bounded continuation, eligibility,
% selection or the original-scale relative-boundary rule. Historical run

scfg = struct();
scfg.classInterior = 'ERROR_MODEL_INTERIOR_SOLUTION';
scfg.classBoundary = 'ERROR_SUPPORT_BOUNDARY_RETAINED';
scfg.classHold = 'ERROR_MODEL_NUMERICAL_HOLD';
scfg.sigmaLower = [1e-6,1e-6];
scfg.sigmaUpper = [10,10];
scfg.supportBoundaryFraction = 0.01;
scfg.directTolerance = 1e-10;
scfg.baseStarts = [0.4,0.25;0.2,0.4;0.7,0.12];
scfg.maxBlocksPerStart = 5;
scfg.blockMaxIterations = 120;
scfg.blockMaxFunctionEvaluations = 600;
scfg.maxIterationsPerStart = 600;
scfg.maxFunctionEvaluationsPerStart = 3000;
scfg.maxStarts = 5;
scfg.maxFitCalls = 25;
scfg.functionTolerance = 1e-10;
scfg.stepTolerance = 1e-10;
scfg.runAllStarts = true;
scfg.selectionPolicy = ...
    'CONVERGED_ONLY_LOWEST_DIRECT_NLL_ALL_SUPPLIED_STARTS';
scfg.likelihoodModel = 'combined';
scfg.lod_ug_L = 0.0163;
end
