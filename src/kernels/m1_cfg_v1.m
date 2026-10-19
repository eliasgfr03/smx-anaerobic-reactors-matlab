function cfg = m1_cfg_v1()
%M1_CFG_V1 Scientific fields used by the M1 context, mapping and engines.
%
% Public-package extraction of the validated implementation configuration.
% This does not define optimization supports, priors, anchors or run budgets.
% Those belong to the individual analyses, not to the shared model engine.

cfg = struct();
cfg.version = 'JWPE_PUBLIC_M1_CONTEXT_v1';
cfg.requiredRelease = '2022b';
cfg.model = 'M1_IRR_SINK';
cfg.temporalLaw = 'NORMALIZED_GOMPERTZ_G1';
cfg.parameters = ["Kd","kb","kG","tinf","Ai"];
cfg.nativeParameters = ["Kd","kb","krev","kG","tinf","Ai"];
cfg.engineParameters = ["Kd","kSigma","Fdir","kG","tinf","Ai"];

cfg.horizon.max_d = 94;
cfg.horizon.switch_d = [49 94];
cfg.audit.regular_d = 0:0.5:94;
cfg.audit.additional_d = unique([49 94 5:5:90]);
cfg.phase.requiredVersion = 'JWPE_PHASE_POLICY_v1_2026-08-19';
cfg.phase.expectedI = 17;
cfg.phase.expectedII = 16;
cfg.phase.expectedIII = 17;
cfg.phase.expectedCalibration = 33;
cfg.phase.expectedHoldout = 17;


cfg.likelihood.model = 'combined';
cfg.likelihood.lod_ug_L = 0.0163;
cfg.likelihood.nErrorParameters = 2;
cfg.likelihood.nMeanM0 = 6;
cfg.likelihood.nMeanM1 = 5;
cfg.likelihood.observationCount = 33;
cfg.tolerance.mapping = 1e-12;
end
