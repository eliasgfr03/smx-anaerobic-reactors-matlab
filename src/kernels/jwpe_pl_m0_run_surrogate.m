function result = jwpe_pl_m0_run_surrogate(problem,cfg)
% Portability-only deltas: exact persisted normalized InitialPoints and no
% per-point exporter/checkpoint. Selection, objective, RNG and recheck are unchanged.
%
% This is the single production entry point for project analyses that require
% numerical optimization. It intentionally does NOT chain another optimizer.
%
% Standard sequence
%   1) validate problem and normalize to [0,1]^n;
%   2) reuse known InitialPoints/Fval when supplied;
%   4) select the best feasible point actually evaluated;
%   5) perform one independent recheck;
%   6) save trials, configuration, diagnostics and stop.

assert(strcmp(cfg.solver,'surrogateopt'),'Only surrogateopt is allowed by this core.');
if cfg.maxFunctionEvaluations~=50 && ~cfg.allowNonstandardBudget
    error(['Nonstandard surrogate budget requested. The frozen production budget is 50. ' ...
        'Only validation or an explicitly approved project exception may override it.']);
end
assert(cfg.minSurrogatePoints<=cfg.maxFunctionEvaluations, ...
    'MinSurrogatePoints exceeds the evaluation budget.');
assert(~isempty(which('surrogateopt')), ...
    'surrogateopt is unavailable. Global Optimization Toolbox is required.');

problem = jwpe_opt_validate_problem(problem,cfg);
initial = jwpe_pl_m0_initial(problem.initialPointsNormalized,cfg.nvar);
nvar = cfg.nvar;
lbU = zeros(1,nvar); ubU = ones(1,nvar);

[objective,getRecorded,getStats] = local_make_objective(problem,cfg);
opts = optimoptions('surrogateopt', ...
    'Display',cfg.display, ...
    'MaxFunctionEvaluations',cfg.maxFunctionEvaluations, ...
    'MinSurrogatePoints',cfg.minSurrogatePoints, ...
    'UseParallel',cfg.useParallel, ...
    'UseVectorized',cfg.useVectorized);

if ~isempty(initial) && isprop(opts,'InitialPoints')
    opts.InitialPoints = initial;
end
if ~isempty(problem.objectiveLimit) && isprop(opts,'ObjectiveLimit')
    opts.ObjectiveLimit = problem.objectiveLimit;
end

checkpointFile = '';
if strcmp(cfg.checkpointPolicy,'always') || ...
        (strcmp(cfg.checkpointPolicy,'expensive_only') && problem.isExpensive)
    if isprop(opts,'CheckpointFile')
        checkpointFile = fullfile(problem.outputDir,'surrogateopt_checkpoint.mat');
        opts.CheckpointFile = checkpointFile;
    end
end

rng(cfg.seed,'twister');
solverTic = tic;
[uSolver,fSolver,exitflag,output,trials] = surrogateopt( ...
    objective,lbU,ubU,opts);
solverElapsed = toc(solverTic);

recorded = getRecorded();
stats = getStats();
trialsTable = local_build_trials_table(trials,recorded,problem,initial,cfg);
[bestU,bestObjective,bestTrial] = local_best_trial(trials,problem,cfg);
bestPhysical = jwpe_opt_denormalize(bestU,problem.lbPhysical,problem.ubPhysical);

recheck = problem.recheckFcn(bestPhysical);
recheckObjective = local_objective_value(recheck);
recheckDelta = recheckObjective-bestObjective;
recheckPass = isfinite(recheckObjective) && ...
    abs(recheckDelta)<=cfg.recheckAbsoluteTolerance;

result = struct();
result.coreVersion = cfg.version;
result.problemName = problem.name;
result.bestNormalized = bestU;
result.bestPhysical = bestPhysical;
result.bestObjective = bestObjective;
result.bestTrialNumber = bestTrial;
result.solverReturnedNormalized = uSolver(:).';
result.solverReturnedPhysical = jwpe_opt_denormalize(uSolver(:).', ...
    problem.lbPhysical,problem.ubPhysical);
result.solverReturnedObjective = fSolver;
result.exitflag = exitflag;
result.output = output;
result.trialsRaw = trials;
result.trialsTable = trialsTable;
result.recordedEvaluations = recorded;
result.objectiveStats = stats;
result.solverElapsed_s = solverElapsed;
result.recheck = recheck;
result.recheckObjective = recheckObjective;
result.recheckDelta = recheckDelta;
result.recheckPASS = recheckPass;
result.checkpointFile = checkpointFile;
result.config = cfg;
result.parameterNames = problem.parameterNames;
result.lbPhysical = problem.lbPhysical;
result.ubPhysical = problem.ubPhysical;
result.outputDir = problem.outputDir;
result.status = local_status(recheckPass,stats.rawForwards,cfg.maxFunctionEvaluations);

% The caller saves one compact endpoint/trace package after all guards pass.

fprintf('\n============================================================\n');
fprintf('JWPE MASTER SURROGATE RESULT | %s\n',problem.name);
fprintf('best objective      = %.12g\n',bestObjective);
fprintf('objective calls     = %d\n',stats.objectiveCalls);
fprintf('raw forwards        = %d\n',stats.rawForwards);
fprintf('independent recheck = %.12g | delta %.3e | %s\n', ...
    recheckObjective,recheckDelta,local_pass_text(recheckPass));
fprintf('status              = %s\n',result.status);
fprintf('outputs             = %s\n',problem.outputDir);
fprintf('============================================================\n');
end

function [fun,getRecorded,getStats] = local_make_objective(problem,cfg)
capacity = max(64,cfg.maxFunctionEvaluations+16);
nvar = cfg.nvar;
U = nan(capacity,nvar); X = nan(capacity,nvar);
objectiveTrace = nan(capacity,1); bestTrace = nan(capacity,1);
sseTrace = nan(capacity,1); forwardTrace = nan(capacity,1);
totalTrace = nan(capacity,1); rawIncTrace = zeros(capacity,1);
elapsedTrace = nan(capacity,1); validTrace = false(capacity,1);
errorID = strings(capacity,1); errorMessage = strings(capacity,1);
used = 0; rawForwards = 0; bestObjective = inf; errorCount = 0; startClock = tic;
fun = @objective;
getRecorded = @snapshot;
getStats = @stats;

    function value = objective(u)
        u = double(u(:).');
        x = jwpe_opt_denormalize(u,problem.lbPhysical,problem.ubPhysical);
        ineq = [];
        if ~isempty(problem.constraintFcnPhysical)
            ineq = double(problem.constraintFcnPhysical(x));
            ineq = ineq(:).';
        end
        try
            if ~isempty(ineq) && any(ineq>0)
                evalOut = struct('valid',false,'objective',cfg.invalidObjectivePenalty, ...
                    'SSE_zero_as_number',NaN,'forwardElapsed_s',0, ...
                    'totalEvaluationElapsed_s',0,'rawForwardIncrement',0);
            else
                evalOut = problem.evaluateFcn(x);
            end
            f = local_objective_value(evalOut);
            if ~isfinite(f)
                f = cfg.invalidObjectivePenalty;
            end
            valid = local_valid(evalOut) && f<cfg.invalidObjectivePenalty;
            rid = local_numeric_field(evalOut,'rawForwardIncrement',double(valid));
            rawForwards = rawForwards + max(0,round(rid));
            record(u,x,f,evalOut,valid,"","");
        catch ME
            if strcmp(ME.identifier,'JWPE:Public:Budget')
                rethrow(ME)
            end
            errorCount = errorCount + 1;
            f = cfg.invalidObjectivePenalty;
            record(u,x,f,struct(),false,string(ME.identifier),string(ME.message));
        end
        if isempty(ineq)
            value = f;
        else
            value = struct('Fval',f,'Ineq',ineq);
        end
    end

    function record(u,x,f,e,valid,eid,emsg)
        used = used + 1;
        if used>capacity
            error('Internal trace capacity exceeded unexpectedly.');
        end
        bestObjective = min(bestObjective,f);
        U(used,:) = u; X(used,:) = x;
        objectiveTrace(used) = f; bestTrace(used) = bestObjective;
        sseTrace(used) = local_numeric_field(e,'SSE_zero_as_number',NaN);
        forwardTrace(used) = local_numeric_field(e,'forwardElapsed_s',NaN);
        totalTrace(used) = local_numeric_field(e,'totalEvaluationElapsed_s',NaN);
        rawIncTrace(used) = local_numeric_field(e,'rawForwardIncrement',0);
        elapsedTrace(used) = toc(startClock); validTrace(used) = valid;
        errorID(used) = eid; errorMessage(used) = emsg;
    end

    function T = snapshot()
        idx = (1:used).';
        T = table(idx,objectiveTrace(idx),bestTrace(idx),sseTrace(idx), ...
            forwardTrace(idx),totalTrace(idx),rawIncTrace(idx),elapsedTrace(idx), ...
            validTrace(idx),errorID(idx),errorMessage(idx), ...
            'VariableNames',{'ObjectiveCall','Objective','BestObjective','SSE', ...
            'ForwardElapsed_s','TotalEvaluationElapsed_s','RawForwardIncrement', ...
            'Elapsed_s','Valid','ErrorID','ErrorMessage'});
        for j=1:nvar
            T.(sprintf('u_%s',char(problem.parameterNames(j)))) = U(idx,j);
            T.(sprintf('%s',char(problem.parameterNames(j)))) = X(idx,j);
        end
    end

    function s = stats()
        s = struct('objectiveCalls',used,'rawForwards',rawForwards, ...
            'errorCount',errorCount,'bestObjectiveSeen',bestObjective, ...
            'elapsed_s',toc(startClock));
    end
end

function T = local_build_trials_table(trials,recorded,problem,initial,cfg)
U = double(trials.X); F = double(trials.Fval(:)); n = size(U,1); nvar = cfg.nvar;
X = jwpe_opt_denormalize(U,problem.lbPhysical,problem.ubPhysical);
feasible = true(n,1);
if isfield(trials,'Ineq') && ~isempty(trials.Ineq)
    feasible = max(double(trials.Ineq),[],2)<=0;
end
source = repmat("surrogate_evaluation",n,1);
if isstruct(initial) && isfield(initial,'Fval')
    for i=1:n
        for k=1:size(initial.X,1)
            if isequal(U(i,:),double(initial.X(k,:))) && ...
                    abs(F(i)-double(initial.Fval(k)))<=max(eps(abs(F(i))),1e-14)
                source(i) = "known_initial_Fval";
                break
            end
        end
    end
end
T = table((1:n).',F,feasible,source, ...
    'VariableNames',{'Trial','Objective','Feasible','Source'});
for j=1:nvar
    T.(sprintf('u_%s',char(problem.parameterNames(j)))) = U(:,j);
    T.(sprintf('%s',char(problem.parameterNames(j)))) = X(:,j);
end

% Match evaluations made in this run to add common diagnostics. Known Fval
% points legitimately have no new forward diagnostics because they were not
% reevaluated.
T.SSE = nan(n,1); T.ForwardElapsed_s = nan(n,1); T.RawForwardIncrement = nan(n,1);
for i=1:n
    for r=1:height(recorded)
        same = true;
        for j=1:nvar
            uName = sprintf('u_%s',char(problem.parameterNames(j)));
            same = same && isequal(U(i,j),recorded.(uName)(r));
        end
        if same && abs(T.Objective(i)-recorded.Objective(r))<=max(1e-12,eps(abs(T.Objective(i))))
            T.SSE(i)=recorded.SSE(r);
            T.ForwardElapsed_s(i)=recorded.ForwardElapsed_s(r);
            T.RawForwardIncrement(i)=recorded.RawForwardIncrement(r);
            break
        end
    end
end
end

function [bestU,bestObjective,bestTrial] = local_best_trial(trials,problem,cfg)
F = double(trials.Fval(:)); feasible = true(size(F));
if isfield(trials,'Ineq') && ~isempty(trials.Ineq)
    feasible = max(double(trials.Ineq),[],2)<=0;
end
valid = feasible & isfinite(F) & F<cfg.invalidObjectivePenalty;
assert(any(valid),'surrogateopt did not evaluate any valid feasible point.');
idx = find(valid); [bestObjective,k] = min(F(valid)); bestTrial = idx(k);
bestU = double(trials.X(bestTrial,:));
assert(all(bestU>=0 & bestU<=1),'Best normalized point lies outside [0,1].');
assert(numel(bestU)==numel(problem.lbPhysical),'Best-point dimension mismatch.');
end

function f = local_objective_value(e)
if isnumeric(e) && isscalar(e)
    f = double(e);
elseif isstruct(e) && isfield(e,'objective')
    f = double(e.objective);
elseif isstruct(e) && isfield(e,'nll')
    f = double(e.nll);
else
    error('Evaluation output must be a scalar or contain objective/nll.');
end
end

function tf = local_valid(e)
if isstruct(e) && isfield(e,'valid'); tf = logical(e.valid); else; tf = true; end
end

function v = local_numeric_field(s,name,defaultValue)
if isstruct(s) && isfield(s,name) && ~isempty(s.(name)) && isnumeric(s.(name))
    v = double(s.(name));
    if ~isscalar(v); v = defaultValue; end
else
    v = defaultValue;
end
end

function s = local_status(recheckPass,rawForwards,budget)
if ~recheckPass
    s = 'REVIEW_RECHECK';
elseif rawForwards>budget
    s = 'REVIEW_BUDGET';
else
    s = 'PASS';
end
end

function txt = local_pass_text(tf)
if tf; txt='PASS'; else; txt='FAIL'; end
end
