function diagnostics = JWPE_OEM_diagnostics_v1_3(problem,run,cfg)
%JWPE_OEM_DIAGNOSTICS_V1_3 Pointwise and phase diagnostics for one MLE run.

obs = problem.data.Cout_ug_L(:);
pred = run.prediction_ug_L(:);
time = problem.data.Time_d(:);
cin = problem.data.Cin_ug_L(:);
d = run.likelihoodDetail;

phase = ones(size(time));
% Reporting at the exact switch day follows the left-limit convention of
% the validated engines: t=49 belongs to phase 1, t=94 to phase 2.
phase(time>49) = 2;
phase(time>94) = 3;

pointTable = table(time,phase,cin,obs,d.isCensored, ...
    repmat(cfg.lod.ug_L,size(obs)),pred,d.sigma,d.rawResidualStored, ...
    d.stdResidual,d.censorProbability,d.logLikContribution, ...
    'VariableNames',{'Time_d','Phase','Cin_ug_L','ObservedStored_ug_L', ...
    'IsLeftCensored','LOD_ug_L','Prediction_ug_L','Sigma_i', ...
    'RawResidualStored','StandardizedResidualQuantified', ...
    'ProbabilityBelowLOD','LogLikContribution'});

phaseRows = cell(0,11);
for p=1:3
    ix = phase==p;
    iq = ix & d.isQuantified;
    z = d.stdResidual(iq);
    rr = obs(iq)-pred(iq);
    if isempty(z)
        meanZ=NaN; sdZ=NaN; rmse=NaN;
    else
        meanZ=mean(z);
        if numel(z)>1; sdZ=std(z,0); else; sdZ=NaN; end
        rmse=sqrt(mean(rr.^2));
    end
    phaseRows(end+1,:) = {problem.reactor,run.modelName,p,nnz(ix), ...
        nnz(iq),nnz(ix & d.isCensored),meanZ,sdZ,rmse, ...
        sum(d.censorProbability(ix)),sum(d.logLikContribution(ix))}; %#ok<AGROW>
end
phaseTable = cell2table(phaseRows,'VariableNames', ...
    {'Reactor','Model','Phase','N','NQuantified','NCensored', ...
    'MeanStdResidual','SDStdResidual','RMSEQuantified_ug_L', ...
    'ExpectedBelowLODCount','LogLikPhase'});

q = d.isQuantified;
zq = d.stdResidual(q);
pq = pred(q);
rq = obs(q)-pred(q);
if numel(zq)>=3
    lag1 = local_corr(zq(1:end-1),zq(2:end));
else
    lag1 = NaN;
end
rawAbsPredCorr = local_corr(abs(rq),pq);
stdAbsPredCorr = local_corr(abs(zq),pq);

cens = d.isCensored;
if any(cens)
    meanProbObservedCensored = mean(d.censorProbability(cens));
    minProbObservedCensored = min(d.censorProbability(cens));
else
    meanProbObservedCensored = NaN;
    minProbObservedCensored = NaN;
end

summary = struct();
summary.nQuantified = nnz(q);
summary.nCensored = nnz(cens);
summary.expectedBelowLODCount = sum(d.censorProbability);
summary.meanProbabilityObservedCensored = meanProbObservedCensored;
summary.minProbabilityObservedCensored = minProbObservedCensored;
summary.standardizedResidualLag1 = lag1;
summary.rawAbsResidualVsPredictionCorr = rawAbsPredCorr;
summary.stdAbsResidualVsPredictionCorr = stdAbsPredCorr;
if any(q)
    summary.meanStandardizedResidual = mean(zq);
    summary.sdStandardizedResidual = std(zq,0);
else
    summary.meanStandardizedResidual = NaN;
    summary.sdStandardizedResidual = NaN;
end

diagnostics = struct('pointTable',pointTable,'phaseTable',phaseTable, ...
    'summary',summary);
end

function r = local_corr(x,y)
x=x(:); y=y(:);
valid=isfinite(x)&isfinite(y);
x=x(valid); y=y(valid);
if numel(x)<3 || std(x)==0 || std(y)==0
    r=NaN;
    return
end
C=corrcoef(x,y);
r=C(1,2);
end
