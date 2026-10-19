function out = ofl_sigma_own_v1(prediction,ctx,cfg,initialGuess,progressFile)
%OFL_SIGMA_V1 Isolated sigma-v3 algorithm: OFL LOD, no neighbor, append-only log.
% Algorithm/source delta is recorded in SIGMA_DELTA_v1.md.

if nargin<4
    initialGuess = [];
end
if nargin<5
    progressFile = '';
end
started = tic;
prediction = double(prediction(:));
observed = double(ctx.observed_ug_L(:));
assert(numel(prediction)==33 && numel(observed)==33 && ...
    all(isfinite(prediction)) && all(isfinite(observed)), ...
    'JWPE:M1PL:Likelihood','Expected 33 finite Phase-I-II values.');
assert(numel(ctx.observationPhaseI)==33 && ...
    numel(ctx.observationPhaseII)==33 && ...
    nnz(ctx.observationPhaseI)==17 && nnz(ctx.observationPhaseII)==16 && ...
    ~any(ctx.observationPhaseI & ctx.observationPhaseII) && ...
    all(ctx.observationPhaseI | ctx.observationPhaseII), ...
    'JWPE:M1PL:Likelihood','Phase likelihood partition mismatch.');

scfg = ofl_sigcfg_own_v1(cfg);
assert(isempty(initialGuess),'OFL:Sigma','Neighbor starts are prohibited.');
local_frozen_policy(cfg,scfg);
cfgInf = struct('observation',struct('model','combined','lod_ug_L',0.198), ...
    'errorProfile',struct('invalidPenalty',1e12));
assert(strcmp(cfgInf.observation.model,cfg.likelihood.model) && ...
    cfgInf.observation.lod_ug_L==cfg.likelihood.lod_ug_L, ...
    'JWPE:M1PL:Likelihood','Likelihood model or LOD mismatch.');
[starts,sigmaLower,sigmaUpper] = local_starts(prediction,observed, ...
    cfg,initialGuess);
assert(size(starts,1)<=scfg.maxStarts && size(starts,2)==2, ...
    'JWPE:M1PL:Likelihood','Sigma start count exceeds the approved cap.');

logLower = log(sigmaLower(:));
logUpper = log(sigmaUpper(:));
modelName = lower(string(cfg.likelihood.model));
lod = cfg.likelihood.lod_ug_L;
objective = @(x)local_objective(x,logLower,logUpper,prediction, ...
    observed,modelName,lod,cfgInf.errorProfile.invalidPenalty);
options = optimset('Display','off', ...
    'MaxIter',scfg.blockMaxIterations, ...
    'MaxFunEvals',scfg.blockMaxFunctionEvaluations, ...
    'TolFun',scfg.functionTolerance,'TolX',scfg.stepTolerance);

nStarts = size(starts,1);
rows = repmat(local_row(),scfg.maxFitCalls,1);
outputs = cell(scfg.maxFitCalls,1);
fitCall = 0;
cumulativeIterations = zeros(nStarts,1);
cumulativeFunctionCount = zeros(nStarts,1);
terminalState = strings(nStarts,1);
for startIndex = 1:nStarts
    currentX = log(starts(startIndex,:).');
    for block = 1:scfg.maxBlocksPerStart
        startSigma = exp(currentX(:)).';
        screenNLL = jwpe_inf_observation_loglik(prediction,observed, ...
            modelName,startSigma(:),lod);
        runTic = tic;
        [x,optimizerNLL,exitflag,info] = fminsearch(objective, ...
            currentX,options);
        elapsed = toc(runTic);
        x = double(x(:));
        sigma = exp(x).';
        iterations = local_field(info,'iterations');
        functionCount = local_field(info,'funcCount');
        cumulativeIterations(startIndex) = ...
            cumulativeIterations(startIndex)+iterations;
        cumulativeFunctionCount(startIndex) = ...
            cumulativeFunctionCount(startIndex)+functionCount;
        directNLL = NaN;
        if numel(sigma)==2 && all(isfinite(sigma)) && ...
                all(sigma>=sigmaLower) && all(sigma<=sigmaUpper)
            directNLL = jwpe_inf_observation_loglik(prediction,observed, ...
                modelName,sigma(:),lod);
        end
        eligibility = m1pl_elig_v3(optimizerNLL,directNLL,sigma, ...
            sigmaLower,sigmaUpper,exitflag,scfg.directTolerance);
        boundary = m1pl_bound_v3(sigma,sigmaLower,sigmaUpper, ...
            scfg.supportBoundaryFraction);
        stopReason = local_stop_reason(eligibility,block,scfg);
        fitCall = fitCall+1;
        rows(fitCall,1) = local_make_row(startIndex,block,startSigma, ...
            screenNLL,sigma,optimizerNLL,directNLL,exitflag,info, ...
            iterations,functionCount,cumulativeIterations(startIndex), ...
            cumulativeFunctionCount(startIndex),eligibility,boundary, ...
            stopReason,elapsed);
        outputs{fitCall,1} = info;
        assert(cumulativeIterations(startIndex)<= ...
            scfg.maxIterationsPerStart && ...
            cumulativeFunctionCount(startIndex)<= ...
            scfg.maxFunctionEvaluationsPerStart, ...
            'JWPE:M1PL:Likelihood','Sigma continuation cap exceeded.');
        local_progress(progressFile,starts,rows(1:fitCall), ...
            cumulativeIterations, ...
            cumulativeFunctionCount,started);
        if eligibility.eligible
            terminalState(startIndex) = "CONVERGED_ELIGIBLE";
            break
        end
        if ~eligibility.continuationEligible
            terminalState(startIndex) = string(eligibility.reason);
            break
        end
        if block==scfg.maxBlocksPerStart
            terminalState(startIndex) = "CONTINUATION_CAP_EXHAUSTED";
            break
        end
        currentX = x;
    end
end

rows = rows(1:fitCall);
outputs = outputs(1:fitCall);
runs = struct2table(rows);
assert(height(runs)<=scfg.maxFitCalls, ...
    'JWPE:M1PL:Likelihood','Sigma fit-call cap exceeded.');
eligibleRows = find(runs.Eligible);
out = local_empty_output(starts,runs,outputs,cumulativeIterations, ...
    cumulativeFunctionCount,terminalState,scfg,toc(started));
if isempty(eligibleRows)
    out.status = scfg.classHold;
    out.classification = scfg.classHold;
    out.numericalHoldReason = ...
        'NO_ELIGIBLE_START_AFTER_BOUNDED_CONTINUATION';
    local_complete_progress(progressFile,out);
    return
end

[~,minimumIndex] = min(runs.DirectNLL(eligibleRows));
selectedRow = eligibleRows(minimumIndex);
selectedSigma = [runs.EndSigmaA(selectedRow), ...
    runs.EndSigmaP(selectedRow)];
[nllCheck,detail] = jwpe_inf_observation_loglik(prediction,observed, ...
    modelName,selectedSigma(:),lod);
selectedEligibility = m1pl_elig_v3(runs.OptimizerNLL(selectedRow), ...
    nllCheck,selectedSigma,sigmaLower,sigmaUpper, ...
    runs.Exitflag(selectedRow),scfg.directTolerance);
assert(selectedEligibility.eligible && ...
    abs(nllCheck-runs.DirectNLL(selectedRow))<=scfg.directTolerance, ...
    'JWPE:M1PL:Likelihood','Selected direct NLL is not reproducible.');
boundary = m1pl_bound_v3(selectedSigma,sigmaLower,sigmaUpper, ...
    scfg.supportBoundaryFraction);
nllPhaseI = -sum(detail.logLikContribution(ctx.observationPhaseI));
nllPhaseII = -sum(detail.logLikContribution(ctx.observationPhaseII));
assert(isfinite(nllPhaseI) && isfinite(nllPhaseII) && ...
    abs(nllPhaseI+nllPhaseII-nllCheck)<=scfg.directTolerance, ...
    'JWPE:M1PL:Likelihood','Phase likelihood partition mismatch.');

out.status = 'NUMERICALLY_COMPLETE';
out.classification = boundary.classification;
out.nll = nllCheck;
out.sigmaA = selectedSigma(1);
out.sigmaP = selectedSigma(2);
out.nllPhaseI = nllPhaseI;
out.nllPhaseII = nllPhaseII;
out.censoredCount = nnz(detail.isCensored);
out.quantifiedCount = nnz(detail.isQuantified);
out.exitflag = runs.Exitflag(selectedRow);
out.optimizerOutput = outputs{selectedRow};
out.eligibleRows = eligibleRows(:).';
out.nEligibleRuns = numel(eligibleRows);
out.selectedRow = selectedRow;
out.selectedStartIndex = runs.StartIndex(selectedRow);
out.selectedBlock = runs.Block(selectedRow);
out.directRecalculationDelta = ...
    nllCheck-runs.OptimizerNLL(selectedRow);
out.supportReview = boundary.errorSupportBoundaryReview;
out.errorSupportBoundaryReview = boundary.errorSupportBoundaryReview;
out.boundaryFlags = boundary.flagNames;
out.sigmaALowerBoundaryRetained = ...
    boundary.sigmaALowerBoundaryRetained;
out.sigmaAUpperBoundaryRetained = ...
    boundary.sigmaAUpperBoundaryRetained;
out.sigmaPLowerBoundaryRetained = ...
    boundary.sigmaPLowerBoundaryRetained;
out.sigmaPUpperBoundaryRetained = ...
    boundary.sigmaPUpperBoundaryRetained;
out.distanceSigmaAFromLower = boundary.distanceSigmaAFromLower;
out.distanceSigmaAFromUpper = boundary.distanceSigmaAFromUpper;
out.distanceSigmaPFromLower = boundary.distanceSigmaPFromLower;
out.distanceSigmaPFromUpper = boundary.distanceSigmaPFromUpper;
out.detail = detail;
out.elapsed_s = toc(started);
local_complete_progress(progressFile,out);
end

function local_frozen_policy(cfg,scfg)
assert(strcmp(cfg.likelihood.model,scfg.likelihoodModel) && ...
    cfg.likelihood.lod_ug_L==scfg.lod_ug_L && ...
    isequal(cfg.likelihood.sigmaLower,scfg.sigmaLower) && ...
    isequal(cfg.likelihood.sigmaUpper,scfg.sigmaUpper) && ...
    isequal(cfg.likelihood.baseStarts,scfg.baseStarts) && ...
    cfg.likelihood.runAllStarts && ...
    cfg.likelihood.MaxIter==scfg.blockMaxIterations && ...
    cfg.likelihood.MaxFunEvals==scfg.blockMaxFunctionEvaluations && ...
    cfg.likelihood.TolFun==scfg.functionTolerance && ...
    cfg.likelihood.TolX==scfg.stepTolerance && ...
    cfg.likelihood.directTolerance==scfg.directTolerance && ...
    cfg.likelihood.supportBoundaryFraction== ...
    scfg.supportBoundaryFraction, ...
    'JWPE:M1PL:Likelihood','Frozen sigma configuration mismatch.');
end

function [starts,lower,upper] = local_starts(prediction,observed,cfg, ...
        initialGuess)
lower = cfg.likelihood.sigmaLower;
upper = cfg.likelihood.sigmaUpper;
quantified = observed>0;
residual = observed(quantified)-prediction(quantified);
rmsAbsolute = sqrt(mean(residual.^2));
rmsAbsolute = min(max(rmsAbsolute,lower(1)),upper(1));
relativeScale = sqrt(mean((residual./max(abs(prediction(quantified)), ...
    cfg.likelihood.lod_ug_L)).^2));
relativeScale = min(max(relativeScale,lower(2)),upper(2));
dataStart = [rmsAbsolute,max(0.5*relativeScale,lower(2))];
starts = [cfg.likelihood.baseStarts;dataStart];
if ~isempty(initialGuess)
    initialGuess = double(initialGuess(:).');
    assert(numel(initialGuess)==2 && all(isfinite(initialGuess)), ...
        'JWPE:M1PL:Likelihood','Invalid supplied sigma neighbor.');
    starts = [starts;initialGuess];
end
starts = min(max(starts,lower),upper);
starts = unique(starts,'rows','stable');
end

function value = local_objective(x,lower,upper,prediction,observed, ...
        modelName,lod,penalty)
x = x(:);
violation = max(lower-x,0)+max(x-upper,0);
if any(violation>0)
    value = penalty+1e6*sum(violation.^2);
    return
end
value = jwpe_inf_observation_loglik(prediction,observed,modelName, ...
    exp(x),lod);
if ~isfinite(value)
    value = penalty;
end
end

function reason = local_stop_reason(eligibility,block,scfg)
if eligibility.eligible
    reason = "CONVERGED_ELIGIBLE";
elseif ~eligibility.continuationEligible
    reason = string(eligibility.reason);
elseif block==scfg.maxBlocksPerStart
    reason = "CONTINUATION_CAP_EXHAUSTED";
else
    reason = "CONTINUE_FROM_ENDPOINT";
end
end

function out = local_empty_output(starts,runs,outputs,cumulativeIterations, ...
        cumulativeFunctionCount,terminalState,scfg,elapsed)
startsTable = table((1:size(starts,1)).',starts(:,1),starts(:,2), ...
    'VariableNames',{'StartIndex','SigmaA','SigmaP'});
out = struct();
out.status = scfg.classHold;
out.classification = scfg.classHold;
out.numericalHoldReason = '';
out.selectionPolicy = scfg.selectionPolicy;
out.starts = startsTable;
out.startRuns = runs;
out.blockOutputs = outputs;
out.nCandidateStarts = height(startsTable);
out.nOptimizedStarts = height(startsTable);
out.nFitCalls = height(runs);
out.nBlocksCompleted = max(runs.Block);
out.totalIterations = sum(runs.Iterations);
out.totalFunctionCount = sum(runs.FunctionCount);
out.cumulativeIterationsPerStart = cumulativeIterations;
out.cumulativeFunctionCountPerStart = cumulativeFunctionCount;
out.startTerminalState = terminalState;
out.maxBlocksPerStart = scfg.maxBlocksPerStart;
out.maxIterationsPerStart = scfg.maxIterationsPerStart;
out.maxFunctionEvaluationsPerStart = ...
    scfg.maxFunctionEvaluationsPerStart;
out.maxFitCalls = scfg.maxFitCalls;
out.nll = NaN;
out.sigmaA = NaN;
out.sigmaP = NaN;
out.nllPhaseI = NaN;
out.nllPhaseII = NaN;
out.censoredCount = NaN;
out.quantifiedCount = NaN;
out.exitflag = NaN;
out.optimizerOutput = struct();
out.eligibleRows = zeros(1,0);
out.nEligibleRuns = 0;
out.selectedRow = NaN;
out.selectedStartIndex = NaN;
out.selectedBlock = NaN;
out.directRecalculationDelta = NaN;
out.supportReview = false;
out.errorSupportBoundaryReview = false;
out.boundaryFlags = strings(1,0);
out.sigmaALowerBoundaryRetained = false;
out.sigmaAUpperBoundaryRetained = false;
out.sigmaPLowerBoundaryRetained = false;
out.sigmaPUpperBoundaryRetained = false;
out.distanceSigmaAFromLower = NaN;
out.distanceSigmaAFromUpper = NaN;
out.distanceSigmaPFromLower = NaN;
out.distanceSigmaPFromUpper = NaN;
out.detail = struct();
out.mechanisticForwards = 0;
out.retries = 0;
out.elapsed_s = elapsed;
end

function local_progress(file,starts,rows,cumulativeIterations, ...
        cumulativeFunctionCount,started)
if strlength(string(file))==0
    return
end
progress = struct();
progress.status = 'SIGMA_BOUNDARY_V3_IN_PROGRESS';
progress.starts = starts;
progress.startRuns = struct2table(rows);
progress.cumulativeIterationsPerStart = cumulativeIterations;
progress.cumulativeFunctionCountPerStart = cumulativeFunctionCount;
progress.fitCallsCompleted = numel(rows);
progress.mechanisticForwards = 0;
progress.elapsed_s = toc(started);
progress.recordedAt = char(datetime('now','TimeZone','local', ...
    'Format','yyyy-MM-dd''T''HH:mm:ssXXX'));
ofl_sigprog_v1(file,progress);
end

function local_complete_progress(file,out)
if strlength(string(file))==0
    return
end
progress = out;
progress.status = 'SIGMA_BOUNDARY_V3_COMPLETE';
progress.recordedAt = char(datetime('now','TimeZone','local', ...
    'Format','yyyy-MM-dd''T''HH:mm:ssXXX'));
ofl_sigprog_v1(file,progress);
end

function row = local_row()
row = struct('StartIndex',NaN,'Block',NaN,'StartSigmaA',NaN, ...
    'StartSigmaP',NaN,'ScreenNLL',NaN,'EndSigmaA',NaN, ...
    'EndSigmaP',NaN,'OptimizerNLL',NaN,'DirectNLL',NaN, ...
    'DirectDelta',NaN,'Exitflag',NaN,'Iterations',NaN, ...
    'FunctionCount',NaN,'CumulativeIterations',NaN, ...
    'CumulativeFunctionCount',NaN,'WithinSupport',false, ...
    'FiniteResult',false,'DirectAgreement',false,'Eligible',false, ...
    'ContinuationEligible',false,'NearLowerSigmaA',false, ...
    'NearUpperSigmaA',false,'NearLowerSigmaP',false, ...
    'NearUpperSigmaP',false,'DistanceSigmaAFromLower',NaN, ...
    'DistanceSigmaAFromUpper',NaN,'DistanceSigmaPFromLower',NaN, ...
    'DistanceSigmaPFromUpper',NaN,'StopReason',"", ...
    'OutputMessage',"",'Elapsed_s',NaN);
end

function row = local_make_row(startIndex,block,startSigma,screenNLL, ...
        sigma,optimizerNLL,directNLL,exitflag,info,iterations, ...
        functionCount,cumulativeIterations,cumulativeFunctionCount, ...
        eligibility,boundary,stopReason,elapsed)
row = local_row();
row.StartIndex = startIndex;
row.Block = block;
row.StartSigmaA = startSigma(1);
row.StartSigmaP = startSigma(2);
row.ScreenNLL = screenNLL;
if numel(sigma)==2
    row.EndSigmaA = sigma(1);
    row.EndSigmaP = sigma(2);
end
row.OptimizerNLL = optimizerNLL;
row.DirectNLL = directNLL;
row.DirectDelta = eligibility.directDelta;
row.Exitflag = exitflag;
row.Iterations = iterations;
row.FunctionCount = functionCount;
row.CumulativeIterations = cumulativeIterations;
row.CumulativeFunctionCount = cumulativeFunctionCount;
row.WithinSupport = eligibility.withinSupport;
row.FiniteResult = eligibility.finiteResult;
row.DirectAgreement = eligibility.directAgreement;
row.Eligible = eligibility.eligible;
row.ContinuationEligible = eligibility.continuationEligible;
row.NearLowerSigmaA = boundary.sigmaALowerBoundaryRetained;
row.NearUpperSigmaA = boundary.sigmaAUpperBoundaryRetained;
row.NearLowerSigmaP = boundary.sigmaPLowerBoundaryRetained;
row.NearUpperSigmaP = boundary.sigmaPUpperBoundaryRetained;
row.DistanceSigmaAFromLower = boundary.distanceSigmaAFromLower;
row.DistanceSigmaAFromUpper = boundary.distanceSigmaAFromUpper;
row.DistanceSigmaPFromLower = boundary.distanceSigmaPFromLower;
row.DistanceSigmaPFromUpper = boundary.distanceSigmaPFromUpper;
row.StopReason = stopReason;
row.OutputMessage = local_text(info,'message');
row.Elapsed_s = elapsed;
end

function value = local_field(valueStruct,name)
if isstruct(valueStruct) && isfield(valueStruct,name) && ...
        ~isempty(valueStruct.(name))
    value = double(valueStruct.(name));
else
    value = 0;
end
end

function value = local_text(valueStruct,name)
if isstruct(valueStruct) && isfield(valueStruct,name) && ...
        ~isempty(valueStruct.(name))
    value = string(valueStruct.(name));
else
    value = "";
end
end
