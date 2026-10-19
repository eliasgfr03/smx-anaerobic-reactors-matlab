function policy = jwpe_phase_policy_v1(time_d)
%JWPE_PHASE_POLICY_V1 Prospective calibration/validation partition for JWPE.
%
% GLOBAL PROJECT RULE (approved 2026-08-19)
%   Phase I + Phase II are the ONLY observations available for calibration,
%   structural selection, profile likelihood, GSA, deterministic calibration,
%   and MCMC from Stage 03B onward.
%
%   Phase III is reserved for final direct validation of the frozen model,
%   after deterministic calibration + MCMC and before scenario analysis.
%
% OBSERVATION-TIME CONVENTION
%   The observations at the hydraulic-switch days (49 d and 94 d) belong to
%   the phase that ends on that sampling day. Therefore:
%       Phase I   : t <= 49 d
%       Phase II  : 49 < t <= 94 d
%       Phase III : t > 94 d
%   In the current experimental datasets this yields 17/16/17 observations.
%
% This function deliberately returns masks only; it never exposes or consumes
% Phase III response values. Stage-specific code decides when holdout values
% may be read, and until final validation that must remain prohibited.

if nargin<1 || isempty(time_d)
    error('time_d is required.');
end
t = double(time_d(:));
assert(all(isfinite(t)) && all(diff(t)>=0), ...
    'time_d must be finite and nondecreasing.');

policy = struct();
policy.version = 'JWPE_PHASE_POLICY_v1_2026-08-19';
policy.phaseI_end_d = 49;
policy.phaseII_end_d = 94;
policy.phaseIII_start_after_d = 94;
policy.phaseI = t<=policy.phaseI_end_d;
policy.phaseII = t>policy.phaseI_end_d & t<=policy.phaseII_end_d;
policy.phaseIII = t>policy.phaseII_end_d;
policy.calibration = policy.phaseI | policy.phaseII;
policy.validation = policy.phaseIII;
policy.countPhaseI = nnz(policy.phaseI);
policy.countPhaseII = nnz(policy.phaseII);
policy.countPhaseIII = nnz(policy.phaseIII);
policy.countCalibration = nnz(policy.calibration);
policy.countValidation = nnz(policy.validation);
policy.calibrationMaxTime_d = max(t(policy.calibration));
policy.validationMinTime_d = min(t(policy.validation));

% Current dataset-specific continuity guards. These are intentional: if the
% source observation schedule changes, the split must be reviewed explicitly
% rather than silently moving observations between calibration and validation.
assert(numel(t)==50,'Expected the approved 50-observation JWPE dataset.');
assert(policy.countPhaseI==17 && policy.countPhaseII==16 && ...
    policy.countPhaseIII==17,'Unexpected Phase I/II/III observation counts.');
assert(policy.countCalibration==33 && policy.countValidation==17, ...
    'Unexpected calibration/validation observation counts.');
assert(abs(policy.calibrationMaxTime_d-94)<=1e-12, ...
    'Calibration set must end at the day-94 observation.');
assert(abs(policy.validationMinTime_d-103)<=1e-12, ...
    'Current Phase III holdout must begin at the day-103 observation.');
assert(~any(policy.calibration & policy.validation), ...
    'Calibration and validation masks overlap.');
assert(all(policy.calibration | policy.validation), ...
    'Every observation must belong to calibration or validation.');
end
