function cfg = jwpe_03b_log2_config_v1(cfgCore,cfgBase)
%JWPE_03B_LOG2_CONFIG_V1 Approved final structural test within Stage 03B.
%
% QUESTION
%   Can the adaptive biotransformation capacity be represented by a
%   normalized two-parameter logistic law without material loss of fit
%   relative to the current three-parameter G1 law?
%
% LOG2
%   A(t) = 1/(1 + exp(-kA*(t-t50)))
%   Free mechanistic parameters: [Kd kb krev kA t50].
%   A(infinity)=1 and A(t50)=0.5 exactly. A(0) is implied, not fitted.
%
% DATA POLICY
%   Only Phases I-II (through day 94) may enter optimization. Phase III is
%   reserved for final direct validation and is never evaluated here.
%
% COMPUTATION
%   recheck per reactor. Existing G1 Stage-03B results are reused, not rerun.

assert(isstruct(cfgCore) && isfield(cfgCore,'mean'), ...
    'Validated Inference Core configuration is required.');
assert(isstruct(cfgBase) && isfield(cfgBase,'stageVersion'), ...
    'Validated Stage-03B G1-vs-A1 configuration is required.');

cfg = struct();
cfg.stageVersion = 'JWPE_STAGE_03B_LOG2_VS_G1_v1_2026-08-19';
cfg.project = 'JWPE-D-26-03371';
cfg.phasePolicyRequired = 'JWPE_PHASE_POLICY_v1_2026-08-19';
cfg.requiredG1StageVersion = 'JWPE_STAGE_03B_G1_VS_A1_v1_2026-08-19';

cfg.LOG2.parameterNames = ["Kd","kb","krev","kA","t50"];
cfg.LOG2.parameterUnits = ["L/gTSS","L/(gVSS d)","L/(gVSS d)","1/d","d"];
cfg.LOG2.bounds = [cfgCore.mean.bounds(1:3,:); 0.01 4.0; 0 94];

% Information criteria count the same two profiled error parameters in both
% models. G1 has six mechanistic parameters; LOG2 has five.
cfg.informationCriteria.nErrorParameters = 2;
cfg.informationCriteria.nMeanParametersG1 = 6;
cfg.informationCriteria.nMeanParametersLOG2 = 5;

cfg.validation.expectedCalibrationObs = 33;
cfg.validation.expectedHoldoutObs = 17;
cfg.validation.maxG1PredictionAbs_ug_L = 1e-10;
cfg.validation.maxFastVsRobustDeltaNLL = cfgCore.quality.nllReferenceTolerance;
cfg.validation.activityHalfTolerance = 1e-14;
cfg.validation.activityRangeTolerance = 1e-14;
cfg.validation.activityMonotonicTolerance = 1e-13;

cfg.activityGridStep_d = 0.1;
cfg.output.pngResolution = 600;
cfg.output.writeCSV = true;
cfg.output.writeExcel = true;
cfg.output.writeMAT = true;
end
