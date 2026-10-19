function out = jwpe_03b_log2_evaluate_v1(x,ctx,cfgCore,cfgStage,robustErrorProfile)
%JWPE_03B_LOG2_EVALUATE_V1 Phase-I/II-only LOG2 likelihood evaluation.

if nargin<5 || isempty(robustErrorProfile); robustErrorProfile=false; end
x=double(x(:).'); assert(numel(x)==5,'Expected [Kd kb krev kA t50].');

% Box support is checked here too because the independent recheck bypasses
b=cfgStage.LOG2.bounds;
boxOK=all(x(:)>=b(:,1) & x(:)<=b(:,2));
c=jwpe_03b_native_ineq_v1(x(1:3),cfgCore);
supportOK=boxOK && all(c<=0);
if ~supportOK
    out=local_invalid(x,c);
    return
end

t=tic;
% Same source simulator, routed through the external before-attempt ledger.
sim=ctx.LOG2.simulateRaw(x,logical(robustErrorProfile));
forwardElapsed=toc(t);
pred=sim.prediction_ug_L(:); obs=ctx.calibrationObserved_ug_L(:);
assert(numel(pred)==ctx.nCalibrationObs,'LOG2 output count mismatch.');

cfgProfile=cfgCore;
cfgProfile.errorProfile.runAllStarts=logical(robustErrorProfile);
fit=jwpe_inf_profile_observation_error(pred,obs,cfgProfile);
m=local_metrics(pred,obs);
stateValid=sim.min_SMX>=cfgCore.quality.minimumStateTolerance && ...
    sim.min_TP>=cfgCore.quality.minimumStateTolerance;
valid=isfinite(fit.nll) && stateValid && all(isfinite(pred));
objective=fit.nll; if ~valid; objective=Inf; end
kSigma=x(2)+x(3); Fdir=x(2)/kSigma;

out=struct('model','LOG2','valid',valid,'objective',objective,'nll',fit.nll, ...
    'logLik',fit.logLik,'errorFit',fit,'prediction_ug_L',pred, ...
    'observed_ug_L',obs,'SSE_zero_as_number',m.SSE,'RMSE',m.RMSE, ...
    'NRMSE',m.NRMSE,'NSE',m.NSE,'bias',m.bias, ...
    'forwardElapsed_s',forwardElapsed,'errorProfileElapsed_s',fit.elapsed_s, ...
    'totalEvaluationElapsed_s',forwardElapsed+fit.elapsed_s, ...
    'rawForwardIncrement',1,'minSMX',sim.min_SMX,'minTP',sim.min_TP, ...
    'freeParameters',x,'thetaNativeKinetics',x(1:3),'kA',x(4),'t50',x(5), ...
    'A0',jwpe_03b_log2_activity_v1(0,x(4),x(5)), ...
    'kSigma',kSigma,'Fdir',Fdir,'nativeIneq',c, ...
    'robustErrorProfile',logical(robustErrorProfile));
end

function out=local_invalid(x,c)
out=struct('model','LOG2','valid',false,'objective',Inf,'nll',Inf,'logLik',-Inf, ...
    'errorFit',struct(),'prediction_ug_L',[],'observed_ug_L',[], ...
    'SSE_zero_as_number',NaN,'RMSE',NaN,'NRMSE',NaN,'NSE',NaN,'bias',NaN, ...
    'forwardElapsed_s',0,'errorProfileElapsed_s',0,'totalEvaluationElapsed_s',0, ...
    'rawForwardIncrement',0,'minSMX',NaN,'minTP',NaN,'freeParameters',x, ...
    'thetaNativeKinetics',x(1:3),'kA',x(4),'t50',x(5),'A0',NaN, ...
    'kSigma',NaN,'Fdir',NaN,'nativeIneq',c,'robustErrorProfile',false);
end
function m=local_metrics(pred,obs)
r=pred(:)-obs(:); m.SSE=sum(r.^2); m.RMSE=sqrt(m.SSE/numel(obs));
rngObs=max(obs)-min(obs); if rngObs>0; m.NRMSE=m.RMSE/rngObs; else; m.NRMSE=NaN; end
den=sum((obs-mean(obs)).^2); if den>0; m.NSE=1-m.SSE/den; else; m.NSE=NaN; end
m.bias=mean(r);
end
