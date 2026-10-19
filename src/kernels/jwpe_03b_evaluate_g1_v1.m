function out = jwpe_03b_evaluate_g1_v1(theta,ctx,cfgCore,robustErrorProfile,forceRaw)
%JWPE_03B_EVALUATE_G1_V1 Phase-I/II-only adaptive G1 objective evaluation.

if nargin<4 || isempty(robustErrorProfile); robustErrorProfile = false; end
if nargin<5 || isempty(forceRaw); forceRaw = false; end
theta = double(theta(:).');
assert(numel(theta)==6,'Expected [Kd,kb,krev,kG,tinf,Ai].');

[feasible,support] = jwpe_inf_native_support(theta,cfgCore);
if ~feasible
    out = local_invalid(theta,support);
    return
end

if forceRaw
    simulateFcn = ctx.G1.simulateRaw;
    rawBefore = NaN;
else
    simulateFcn = ctx.G1.simulate;
    rawBefore = local_misses(ctx.G1.getCacheStats());
end

t = tic;
sim = simulateFcn(theta);
forwardElapsed = toc(t);
if forceRaw
    rawIncrement = 1;
else
    rawAfter = local_misses(ctx.G1.getCacheStats());
    rawIncrement = local_raw_increment(rawBefore,rawAfter);
end

pred = sim.prediction_ug_L(:);
obs = ctx.calibrationObserved_ug_L(:);
assert(numel(pred)==ctx.nCalibrationObs,'G1 returned Phase-III or missing outputs.');
cfgProfile = cfgCore;
cfgProfile.errorProfile.runAllStarts = logical(robustErrorProfile);
fit = jwpe_inf_profile_observation_error(pred,obs,cfgProfile);
metrics = local_metrics(pred,obs);
stateValid = sim.min_SMX>=cfgCore.quality.minimumStateTolerance && ...
    sim.min_TP>=cfgCore.quality.minimumStateTolerance;
valid = isfinite(fit.nll) && stateValid && all(isfinite(pred));
objective = fit.nll; if ~valid; objective = Inf; end
[thetaEngine,derived] = jwpe_inf_native_to_engine(theta);

out = struct();
out.model = 'G1';
out.valid = valid;
out.objective = objective;
out.nll = fit.nll;
out.logLik = fit.logLik;
out.errorFit = fit;
out.prediction_ug_L = pred;
out.observed_ug_L = obs;
out.SSE_zero_as_number = metrics.SSE;
out.RMSE = metrics.RMSE;
out.NRMSE = metrics.NRMSE;
out.NSE = metrics.NSE;
out.bias = metrics.bias;
out.forwardElapsed_s = forwardElapsed;
out.errorProfileElapsed_s = fit.elapsed_s;
out.totalEvaluationElapsed_s = forwardElapsed + fit.elapsed_s;
out.rawForwardIncrement = rawIncrement;
out.minSMX = sim.min_SMX;
out.minTP = sim.min_TP;
out.thetaNative = theta;
out.thetaEngine = thetaEngine;
out.kSigma = derived.kSigma;
out.Fdir = derived.Fdir;
out.support = support;
out.robustErrorProfile = logical(robustErrorProfile);
out.independentRecheck = logical(forceRaw);
end

function out = local_invalid(theta,support)
out = struct('model','G1','valid',false,'objective',Inf,'nll',Inf,'logLik',-Inf, ...
    'errorFit',struct(),'prediction_ug_L',[],'observed_ug_L',[], ...
    'SSE_zero_as_number',NaN,'RMSE',NaN,'NRMSE',NaN,'NSE',NaN,'bias',NaN, ...
    'forwardElapsed_s',0,'errorProfileElapsed_s',0,'totalEvaluationElapsed_s',0, ...
    'rawForwardIncrement',0,'minSMX',NaN,'minTP',NaN,'thetaNative',theta, ...
    'thetaEngine',nan(1,6),'kSigma',NaN,'Fdir',NaN,'support',support, ...
    'robustErrorProfile',false,'independentRecheck',false);
end

function n = local_misses(s)
if isstruct(s) && isfield(s,'misses') && isfinite(s.misses); n=double(s.misses); else; n=NaN; end
end
function n = local_raw_increment(a,b)
if isfinite(a) && isfinite(b); n=max(0,b-a); else; n=1; end
end
function m = local_metrics(pred,obs)
r = pred(:)-obs(:); m.SSE=sum(r.^2); m.RMSE=sqrt(m.SSE/numel(obs));
rangeObs=max(obs)-min(obs); if rangeObs>0; m.NRMSE=m.RMSE/rangeObs; else; m.NRMSE=NaN; end
den=sum((obs-mean(obs)).^2); if den>0; m.NSE=1-m.SSE/den; else; m.NSE=NaN; end
m.bias=mean(r);
end
