function run = JWPE_OEM_optimize_v1_3(problem,cfg,modelName,theta0,error0,label)
%JWPE_OEM_OPTIMIZE_V1_3 Fast-search + central-polish joint MLE.
%
% Scientific coordinates: [Kd,kb,krev,kG,tinf,Ai] + observation-error pars.
%
% PERFORMANCE ORGANIZATION
%   Stage 1 SEARCH: forward finite differences, used only to approach the
%                   local optimum efficiently.
%   Stage 2 POLISH: central finite differences from the search endpoint.
%                   Only this polished solution is used for scientific
%                   comparison, stability, ICs and reported parameters.
%
% The objective uses an exact mechanistic-forward cache. If fmincon changes
% only sigmaA/sigmaP, the six mean parameters are identical and the validated
% CS/PF forward result is reused. Independent final recheck bypasses cache.

if nargin<6 || isempty(label); label='OEM_run'; end
spec = JWPE_OEM_model_spec_v1_3(modelName,cfg);
theta0 = theta0(:);
error0 = error0(:);
assert(numel(theta0)==6,'theta0 must contain [Kd,kb,krev,kG,tinf,Ai].');
assert(numel(error0)==spec.nError,'error0 length mismatch.');
assert(local_native_feasible(theta0,cfg), ...
    'Initial native mean parameters are outside the approved equivalent support.');

meanLB = cfg.meanBounds(:,1);
meanUB = cfg.meanBounds(:,2);
errLB = spec.errorBounds(:,1);
errUB = spec.errorBounds(:,2);
error0 = min(max(error0,errLB),errUB);

xLB = [meanLB;log(errLB)];
xUB = [meanUB;log(errUB)];
x0 = [theta0;log(error0)];
u0 = (x0-xLB)./(xUB-xLB);
[A,b,constraintMeta] = JWPE_OEM_native_constraints_v1_3(cfg,spec);
assert(all(A*u0 <= b + cfg.quality.nativeFeasibilityTolerance), ...
    'Initial normalized point violates equivalent-support linear constraints.');

if strcmpi(problem.reactor,'CS')
    maxFESearch = cfg.optimizer.MaxFunctionEvaluations.CS;
    maxFEPolish = cfg.optimizer.polishMaxFunctionEvaluations.CS;
else
    maxFESearch = cfg.optimizer.MaxFunctionEvaluations.PF;
    maxFEPolish = cfg.optimizer.polishMaxFunctionEvaluations.PF;
end

fd = [cfg.fdStepNormalizedMean; ...
    repmat(cfg.fdStepNormalizedError,spec.nError,1)];
objective = @(u)local_objective(u,xLB,xUB,problem,cfg,modelName);
runTic = tic;
cache0 = problem.getCacheStats();

%% Stage 1: fast search
searchTic = tic;
searchProgress = @(x,optimValues,state)local_progress( ...
    optimValues,state,[label ' | SEARCH-FWD'],searchTic,cfg.progress);
searchOptions = optimoptions('fmincon', ...
    'Algorithm',cfg.optimizer.Algorithm, ...
    'Display','off', ...
    'FiniteDifferenceType',cfg.optimizer.searchFiniteDifferenceType, ...
    'FiniteDifferenceStepSize',fd, ...
    'TypicalX',ones(numel(u0),1), ...
    'UseParallel',cfg.optimizer.UseParallel, ...
    'MaxFunctionEvaluations',maxFESearch, ...
    'MaxIterations',cfg.optimizer.MaxIterations, ...
    'FunctionTolerance',cfg.optimizer.FunctionTolerance, ...
    'StepTolerance',cfg.optimizer.StepTolerance, ...
    'OptimalityTolerance',cfg.optimizer.OptimalityTolerance, ...
    'ConstraintTolerance',cfg.optimizer.ConstraintTolerance, ...
    'OutputFcn',searchProgress);
[uSearch,nllSearch,exitSearch,outSearch,lambdaSearch] = ...
    fmincon(objective,u0,A,b,[],[],zeros(size(u0)),ones(size(u0)),[],searchOptions);
searchElapsed = toc(searchTic);
cacheAfterSearch = problem.getCacheStats();

%% Stage 2: central-difference final polish
polishTic = tic;
polishProgress = @(x,optimValues,state)local_progress( ...
    optimValues,state,[label ' | POLISH-CENTRAL'],polishTic,cfg.progress);
polishOptions = optimoptions('fmincon', ...
    'Algorithm',cfg.optimizer.Algorithm, ...
    'Display','off', ...
    'FiniteDifferenceType',cfg.optimizer.polishFiniteDifferenceType, ...
    'FiniteDifferenceStepSize',fd, ...
    'TypicalX',ones(numel(u0),1), ...
    'UseParallel',cfg.optimizer.UseParallel, ...
    'MaxFunctionEvaluations',maxFEPolish, ...
    'MaxIterations',cfg.optimizer.polishMaxIterations, ...
    'FunctionTolerance',cfg.optimizer.FunctionTolerance, ...
    'StepTolerance',cfg.optimizer.StepTolerance, ...
    'OptimalityTolerance',cfg.optimizer.OptimalityTolerance, ...
    'ConstraintTolerance',cfg.optimizer.ConstraintTolerance, ...
    'OutputFcn',polishProgress);
[u,nll,exitflag,output,lambda] = ...
    fmincon(objective,uSearch,A,b,[],[],zeros(size(u0)),ones(size(u0)),[],polishOptions);
polishElapsed = toc(polishTic);
cacheAfterPolish = problem.getCacheStats();

x = xLB + u.*(xUB-xLB);
theta = x(1:6);
errorPars = exp(x(7:end));
[thetaEngine,derived] = JWPE_OEM_native_to_engine_v1_3(theta);

% Independent deterministic forward + likelihood recheck. This deliberately
% bypasses the cache so cache correctness cannot mask a forward mismatch.
recheckTic = tic;
sim = problem.simulateRaw(theta);
recheckForwardElapsed = toc(recheckTic);
[nllCheck,detail] = JWPE_OEM_loglik_v1_3(sim.prediction_ug_L, ...
    problem.data.Cout_ug_L,modelName,errorPars,cfg.lod.ug_L);

positionNormalized = u(:);
atLower = positionNormalized <= cfg.quality.boundDetectionToleranceNormalized;
atUpper = (1-positionNormalized) <= cfg.quality.boundDetectionToleranceNormalized;
linearSlack = b-A*u(:);
linearActive = linearSlack <= cfg.quality.linearConstraintActiveTolerance;
nativeFeasible = local_native_feasible(theta,cfg) && ...
    all(linearSlack >= -cfg.quality.nativeFeasibilityTolerance);

foo = local_field(output,'firstorderopt',NaN);
it = local_field(output,'iterations',NaN);
fc = local_field(output,'funcCount',NaN);
message = local_field(output,'message','');

searchStats = local_stage_stats(nllSearch,exitSearch,outSearch,lambdaSearch, ...
    searchElapsed,cache0,cacheAfterSearch);
polishStats = local_stage_stats(nll,exitflag,output,lambda, ...
    polishElapsed,cacheAfterSearch,cacheAfterPolish);
cacheDeltaTotal = local_cache_delta(cache0,cacheAfterPolish);

run = struct();
run.reactor = problem.reactor;
run.modelName = char(lower(string(modelName)));
run.modelLabel = spec.label;
run.label = char(label);
run.theta0 = theta0(:).';
run.error0 = error0(:).';
run.theta = theta(:).';
run.thetaEngineDerived = thetaEngine(:).';
run.kSigmaDerived = derived.kSigma;
run.FdirDerived = derived.Fdir;
run.errorPars = errorPars(:).';
run.nll = nll;
run.logLik = -nll;
run.nllRecheck = nllCheck;
run.recheckDeltaNLL = nllCheck-nll;
run.exitflag = exitflag;
run.output = output;
run.lambda = lambda;
run.solverMessage = message;
run.firstOrderOptimality = foo;
run.iterations = it;
run.functionCount = fc;
run.elapsed_s = toc(runTic);
run.search = searchStats;
run.polish = polishStats;
run.searchToPolishDeltaNLL = nll-nllSearch;
run.cache = cacheDeltaTotal;
run.rawForwardCallsOptimization = cacheDeltaTotal.misses;
run.rawForwardCallsIndependentRecheck = 1;
run.rawForwardCallsTotal = cacheDeltaTotal.misses + 1;
run.recheckForwardElapsed_s = recheckForwardElapsed;
run.positionNormalized = positionNormalized(:).';
run.atLower = atLower(:).';
run.atUpper = atUpper(:).';
run.meanAtLower = atLower(1:6).';
run.meanAtUpper = atUpper(1:6).';
run.errorAtLower = atLower(7:end).';
run.errorAtUpper = atUpper(7:end).';
run.nativeConstraintLabels = constraintMeta.labels;
run.nativeConstraintSlack = linearSlack(:).';
run.nativeConstraintActive = linearActive(:).';
run.nativeFeasible = nativeFeasible;
run.minSMX = sim.min_SMX;
run.minTP = sim.min_TP;
run.prediction_ug_L = sim.prediction_ug_L(:);
run.likelihoodDetail = detail;
run.SSE_zero_as_number = sum((sim.prediction_ug_L(:)- ...
    problem.data.Cout_ug_L(:)).^2);

collapse = errorPars(:) <= cfg.error.collapseFactor.*errLB;
run.errorComponentCollapsed = collapse(:).';
[run.qualityPass,run.qualityStatus,run.qualityReason] = ...
    local_quality(run,cfg);
end

function f = local_objective(u,xLB,xUB,problem,cfg,modelName)
if any(~isfinite(u)) || any(u<0) || any(u>1)
    f = cfg.optimizer.invalidObjectivePenalty;
    return
end
x = xLB + u(:).*(xUB-xLB);
theta = x(1:6);
errorPars = exp(x(7:end));
try
    sim = problem.simulate(theta);
    [f,~] = JWPE_OEM_loglik_v1_3(sim.prediction_ug_L, ...
        problem.data.Cout_ug_L,modelName,errorPars,cfg.lod.ug_L);
catch ME
    % Portability safety guard only: do not turn an exhausted external
    % forward budget into the historical finite invalid-objective penalty.
    % All other scientific invalid evaluations retain the source behavior.
    if strcmp(ME.identifier,'JWPE:Public:Budget')
        rethrow(ME)
    end
    f = Inf;
end
if ~isfinite(f)
    f = cfg.optimizer.invalidObjectivePenalty;
end
end

function tf = local_native_feasible(theta,cfg)
theta=theta(:);
tol=cfg.quality.nativeFeasibilityTolerance;
b=cfg.meanBounds;
insideBox=all(theta>=b(:,1)-tol & theta<=b(:,2)+tol);
if ~insideBox; tf=false; return; end
try
    [~,d]=JWPE_OEM_native_to_engine_v1_3(theta);
catch
    tf=false; return
end
ks=cfg.equivalentHistoricalSupport.kSigma;
fd=cfg.equivalentHistoricalSupport.Fdir;
tf=d.kSigma>=ks(1)-tol && d.kSigma<=ks(2)+tol && ...
    d.Fdir>=fd(1)-tol && d.Fdir<=fd(2)+tol;
end

function stop = local_progress(optimValues,state,label,runTic,progress)
stop = false;
if ~progress.enabled; return; end
if strcmp(state,'init')
    fprintf('      [solver running] %s\n',label);
elseif strcmp(state,'iter')
    it = local_field(optimValues,'iteration',NaN);
    if it==1 || mod(it,progress.printEveryIterations)==0
        fc = local_field(optimValues,'funccount',NaN);
        fv = local_field(optimValues,'fval',NaN);
        foo = local_field(optimValues,'firstorderopt',NaN);
        fprintf(['        iter=%4g | func=%5g | NLL=%13.7g | ' ...
            'FOO=%10.3g | elapsed=%7.1f s\n'], ...
            it,fc,fv,foo,toc(runTic));
    end
elseif strcmp(state,'done')
    it = local_field(optimValues,'iteration',NaN);
    fc = local_field(optimValues,'funccount',NaN);
    fv = local_field(optimValues,'fval',NaN);
    fprintf('      [solver done] iter=%g | func=%g | NLL=%.12g | %.1f s\n', ...
        it,fc,fv,toc(runTic));
end
end

function value = local_field(s,fieldName,defaultValue)
if isstruct(s) && isfield(s,fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName);
else
    value = defaultValue;
end
end

function d = local_cache_delta(a,b)
d = struct();
d.requests = b.requests-a.requests;
d.hits = b.hits-a.hits;
d.misses = b.misses-a.misses;
d.evictions = b.evictions-a.evictions;
if d.requests>0
    d.hitFraction = d.hits/d.requests;
else
    d.hitFraction = NaN;
end
end

function s = local_stage_stats(nll,exitflag,output,lambda,elapsed,a,b)
s = struct();
s.nll = nll;
s.logLik = -nll;
s.exitflag = exitflag;
s.firstOrderOptimality = local_field(output,'firstorderopt',NaN);
s.iterations = local_field(output,'iterations',NaN);
s.functionCount = local_field(output,'funcCount',NaN);
s.message = local_field(output,'message','');
s.lambda = lambda;
s.elapsed_s = elapsed;
s.cache = local_cache_delta(a,b);
s.rawForwardCalls = s.cache.misses;
end

function [pass,status,reason] = local_quality(run,cfg)
reasons = strings(0,1);
if ~isfinite(run.nll); reasons(end+1)="nonfinite_NLL"; end
if ~(isfinite(run.exitflag) && run.exitflag>0)
    reasons(end+1)="nonpositive_exitflag";
end
tol = max(cfg.quality.recheckNLLAbsTolerance, ...
    cfg.quality.recheckNLLRelTolerance*max(1,abs(run.nll)));
if abs(run.recheckDeltaNLL)>tol
    reasons(end+1)="likelihood_recheck_mismatch";
end
if ~run.nativeFeasible
    reasons(end+1)="native_support_violation";
end
if run.minSMX<cfg.quality.minimumStateTolerance
    reasons(end+1)="SMX_below_tolerance";
end
if run.minTP<cfg.quality.minimumStateTolerance
    reasons(end+1)="TP_below_tolerance";
end
if ~run.likelihoodDetail.valid
    reasons(end+1)="invalid_likelihood";
end
pass = isempty(reasons);
if pass
    reason = 'none';
    if any(run.errorComponentCollapsed)
        status = 'PASS_COMPONENT_COLLAPSE';
    elseif isfinite(run.firstOrderOptimality) && ...
            run.firstOrderOptimality>cfg.quality.fooAdvisoryThreshold
        status = 'PASS_FOO_ADVISORY';
    else
        status = 'PASS';
    end
else
    status = 'FAIL';
    reason = char(strjoin(reasons,';'));
end
end
