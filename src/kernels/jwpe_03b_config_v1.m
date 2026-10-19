function cfg = jwpe_03b_config_v1(cfgCore)
%JWPE_03B_CONFIG_V1 Formal Stage 03B adaptation-evidence configuration.
%
% PUBLIC/SUPPLEMENTARY-MATERIAL QUESTION
%   Does the calibrated model require a time-dependent adaptive
%   biotransformation capacity, or can the same data be explained with
%   constant full capacity A(t)=1 when all remaining applicable mechanistic
%   parameters are recalibrated?
%
% CALIBRATION DATA
%   Phases I-II only. Phase III is reserved for final direct validation and
%   MUST NOT enter this stage objective.
%
% MODELS
%   G1 adaptive: free [Kd kb krev kG tinf Ai] (6 mechanistic parameters).
%   A=1 null   : free [Kd kb krev] (3 mechanistic parameters); kG/tinf are
%                inert engine placeholders and Ai=1 exactly.
%   sigmaA/sigmaP are profiled internally in both models and count as two
%   estimated observation parameters in information criteria.
%
% COMPUTATION
%   objective evaluations maximum, one independent recheck, no polish,
%   multistart, robustness optimization, or automatic extension.

assert(isstruct(cfgCore) && isfield(cfgCore,'mean'), ...
    'Validated Inference Core configuration is required.');

cfg = struct();
cfg.stageVersion = 'JWPE_STAGE_03B_G1_VS_A1_v1_2026-08-19';
cfg.project = 'JWPE-D-26-03371';
cfg.calibrationPolicyRequired = 'JWPE_PHASE_POLICY_v1_2026-08-19';

cfg.G1.freeIdx = 1:6;
cfg.G1.parameterNames = string(cfgCore.mean.paramNames);
cfg.G1.parameterUnits = string(cfgCore.mean.paramUnits);
cfg.G1.bounds = cfgCore.mean.bounds;

cfg.A1.freeIdx = 1:3;
cfg.A1.parameterNames = ["Kd","kb","krev"];
cfg.A1.parameterUnits = ["L/gTSS","L/(gVSS d)","L/(gVSS d)"];
cfg.A1.bounds = cfgCore.mean.bounds(1:3,:);
cfg.A1.fixedAi = 1.0;

% Information-criterion counts. The same two profiled observation-error
% parameters are counted in both models.
cfg.informationCriteria.nErrorParameters = 2;
cfg.informationCriteria.nMeanParametersG1 = 6;
cfg.informationCriteria.nMeanParametersA1 = 3;

cfg.validation.maxFastVsRobustDeltaNLL = cfgCore.quality.nllReferenceTolerance;
cfg.validation.maxA1PlaceholderPredictionDiff_ug_L = 1e-10;
cfg.validation.maxA1ActivityError = 1e-14;
cfg.validation.expectedCalibrationObs = 33;
cfg.validation.expectedHoldoutObs = 17;
cfg.validation.expectedCalibrationCensored = 0;

cfg.output.pngResolution = 600;
cfg.output.writeCSV = true;
cfg.output.writeExcel = true;
cfg.output.writeMAT = true;
end
