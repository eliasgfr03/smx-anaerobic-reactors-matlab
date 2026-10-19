function fit = jwpe_inf_profile_observation_error(pred,obs,cfg,initialGuess)
%JWPE_INF_PROFILE_OBSERVATION_ERROR Profile nuisance observation parameters.
%
% For a FIXED mechanistic prediction, estimate the observation-error
% parameters that minimize the selected negative log-likelihood. This is the
% key computational separation used by future deterministic calibration and
% profile likelihood:
%
%   theta_mean -> ONE mechanistic forward -> yhat
%              -> cheap optimization of sigmaA/sigmaP using yhat only.
%
% No ODE/DAE solver is called inside this function.
%
% NUMERICAL DESIGN
%   The nuisance problem has only one or two variables. We use fminsearch in
%   log(sigma) coordinates, with broad accepted supports enforced by a smooth
%   deterministic penalty outside the box. This avoids nesting fmincon inside
%   a future outer fmincon and keeps the expensive finite-difference layer
%   restricted to mechanistic parameters only.
%
% INPUT initialGuess is optional [sigmaA sigmaP]. A supplied guess is added

if nargin<4; initialGuess = []; end
pred = pred(:);
obs = obs(:);
modelName = lower(string(cfg.observation.model));
lod = cfg.observation.lod_ug_L;

switch modelName
    case "combined"
        sigmaLB = [cfg.observation.sigmaA_bounds(1); ...
                   cfg.observation.sigmaP_bounds(1)];
        sigmaUB = [cfg.observation.sigmaA_bounds(2); ...
                   cfg.observation.sigmaP_bounds(2)];
        baseStarts = cfg.observation.profileStarts;
        assert(size(baseStarts,2)==2,'Combined profile starts must have two columns.');
    case "additive"
        sigmaLB = cfg.observation.sigmaA_bounds(1);
        sigmaUB = cfg.observation.sigmaA_bounds(2);
        baseStarts = cfg.observation.profileStarts(:,1);
    case "proportional"
        sigmaLB = cfg.observation.sigmaP_bounds(1);
        sigmaUB = cfg.observation.sigmaP_bounds(2);
        baseStarts = cfg.observation.profileStarts(:,2);
    otherwise
        error('Unsupported observation model: %s',modelName);
end

% starting point, never the statistical model.
q = obs>0;
resid = obs(q)-pred(q);
rmsAbs = sqrt(mean(resid.^2));
rmsAbs = min(max(rmsAbs,cfg.observation.sigmaA_bounds(1)), ...
    cfg.observation.sigmaA_bounds(2));
relativeScale = sqrt(mean((resid./max(abs(pred(q)),lod)).^2));
relativeScale = min(max(relativeScale,cfg.observation.sigmaP_bounds(1)), ...
    cfg.observation.sigmaP_bounds(2));
if modelName=="combined"
    starts = [baseStarts; rmsAbs max(0.5*relativeScale,sigmaLB(2))];
elseif modelName=="additive"
    starts = [baseStarts(:); rmsAbs];
else
    starts = [baseStarts(:); relativeScale];
end
if ~isempty(initialGuess)
    initialGuess = initialGuess(:).';
    assert(numel(initialGuess)==numel(sigmaLB),'initialGuess length mismatch.');
    starts = [initialGuess; starts];
end
starts = min(max(starts,sigmaLB.'),sigmaUB.');
starts = unique(starts,'rows','stable');

logLB = log(sigmaLB(:));
logUB = log(sigmaUB(:));
objective = @(x)local_bounded_objective(x,logLB,logUB,pred,obs, ...
    modelName,lod,cfg.errorProfile.invalidPenalty);
options = optimset('Display','off', ...
    'MaxIter',cfg.errorProfile.MaxIterations, ...
    'MaxFunEvals',cfg.errorProfile.MaxFunctionEvaluations, ...
    'TolFun',cfg.errorProfile.FunctionTolerance, ...
    'TolX',cfg.errorProfile.StepTolerance);

% Screening costs only likelihood arithmetic. In production, optimize only
startNLL = nan(size(starts,1),1);
for i = 1:size(starts,1)
    startNLL(i) = jwpe_inf_observation_loglik(pred,obs,modelName,starts(i,:).',lod);
end
if cfg.errorProfile.runAllStarts
    indicesToRun = (1:size(starts,1)).';
else
    [~,bestScreened] = min(startNLL);
    indicesToRun = bestScreened;
end

bestNLL = Inf;
bestLogPars = nan(size(logLB));
bestExit = NaN;
bestOutput = struct();
runRows = repmat(struct('start',[],'screenNLL',NaN,'nll',NaN, ...
    'exitflag',NaN,'iterations',NaN,'functionCount',NaN,'elapsed_s',NaN), ...
    numel(indicesToRun),1);
profileTic = tic;

for r = 1:numel(indicesToRun)
    i = indicesToRun(r);
    x0 = log(starts(i,:).');
    thisTic = tic;
    [x,nll,exitflag,output] = fminsearch(objective,x0,options);
    runRows(r).start = starts(i,:);
    runRows(r).screenNLL = startNLL(i);
    runRows(r).nll = nll;
    runRows(r).exitflag = exitflag;
    runRows(r).iterations = local_field(output,'iterations',NaN);
    runRows(r).functionCount = local_field(output,'funcCount',NaN);
    runRows(r).elapsed_s = toc(thisTic);
    if isfinite(nll) && nll<bestNLL
        bestNLL = nll;
        bestLogPars = x(:);
        bestExit = exitflag;
        bestOutput = output;
    end
end

% Final guard: a penalized point outside the accepted supports is not a
% scientific solution even if the direct-search solver stopped there.
if any(bestLogPars<logLB) || any(bestLogPars>logUB)
    error('Observation-error profiling ended outside accepted computational support.');
end
errorPars = exp(bestLogPars);
[nllCheck,detail] = jwpe_inf_observation_loglik(pred,obs,modelName,errorPars,lod);

fit = struct();
fit.modelName = char(modelName);
fit.errorPars = errorPars(:).';
fit.sigmaA = NaN; fit.sigmaP = NaN;
if modelName=="combined"
    fit.sigmaA = errorPars(1); fit.sigmaP = errorPars(2);
elseif modelName=="additive"
    fit.sigmaA = errorPars(1);
else
    fit.sigmaP = errorPars(1);
end
fit.nll = nllCheck;
fit.logLik = -nllCheck;
fit.exitflag = bestExit;
fit.output = bestOutput;
fit.elapsed_s = toc(profileTic);
fit.startRuns = runRows;
fit.nCandidateStarts = size(starts,1);
fit.nOptimizedStarts = numel(runRows);
fit.screenedStartNLL = startNLL(:).';
fit.totalFunctionCount = sum([runRows.functionCount],'omitnan');
fit.detail = detail;
end

function f = local_bounded_objective(x,lb,ub,pred,obs,modelName,lod,penalty)
x = x(:);
lowViolation = max(lb-x,0);
highViolation = max(x-ub,0);
violation = lowViolation + highViolation;
if any(violation>0)
    f = penalty + 1e6*sum(violation.^2);
    return
end
f = jwpe_inf_observation_loglik(pred,obs,modelName,exp(x),lod);
if ~isfinite(f); f = penalty; end
end

function value = local_field(s,name,defaultValue)
if isstruct(s) && isfield(s,name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
