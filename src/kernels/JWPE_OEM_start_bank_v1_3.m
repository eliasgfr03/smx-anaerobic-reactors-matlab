function bank = JWPE_OEM_start_bank_v1_3(problem,cfg,modelName)
%JWPE_OEM_START_BANK_V1_3 Reproducible native anchor + three interior starts.
%
% The mean-parameter bank is unchanged from v1.2. The only performance
% change is that the historical anchor prediction is reused from the problem
% reference instead of rerunning the forward engine for every error model.

spec = JWPE_OEM_model_spec_v1_3(modelName,cfg);
nStarts = cfg.multistart.numberOfStarts;
assert(nStarts==4,'Framework v1.3 expects exactly four pre-specified starts.');

anchorEngine = problem.reference.anchorEngine;
anchor = problem.reference.anchorNative;
startsTheta = nan(nStarts,6);
startsTheta(1,:) = anchor;

rng(cfg.multistart.seed.(problem.reactor),'twister');
margin = cfg.multistart.interiorMargin;
oldK=cfg.equivalentHistoricalSupport.kSigma;
oldF=cfg.equivalentHistoricalSupport.Fdir;
b=cfg.meanBounds;
for i=2:nStarts
    q = margin + (1-2*margin).*rand(1,6);
    Kd=b(1,1)+q(1)*(b(1,2)-b(1,1));
    kSigma=oldK(1)+q(2)*(oldK(2)-oldK(1));
    Fdir=oldF(1)+q(3)*(oldF(2)-oldF(1));
    kG=b(4,1)+q(4)*(b(4,2)-b(4,1));
    tinf=b(5,1)+q(5)*(b(5,2)-b(5,1));
    Ai=b(6,1)+q(6)*(b(6,2)-b(6,1));
    startsTheta(i,:)=JWPE_OEM_engine_to_native_v1_3( ...
        [Kd,kSigma,Fdir,kG,tinf,Ai]);
end

% Initial residual scales from the historical anchor; censored records are
% excluded only from this start-scale heuristic, not from fitted likelihood.
pred = problem.reference.anchorSimulation.prediction_ug_L(:);
obs = problem.data.Cout_ug_L(:);
q = problem.isQuantified;
rq = obs(q)-pred(q);
sigmaA0 = sqrt(mean(rq.^2));
if ~isfinite(sigmaA0) || sigmaA0<=0; sigmaA0 = 0.5; end
rel = abs(rq)./max(abs(pred(q)),cfg.lod.ug_L);
sigmaP0 = median(rel);
if ~isfinite(sigmaP0) || sigmaP0<=0; sigmaP0 = 0.5; end

switch lower(string(modelName))
    case "additive"
        baseError = sigmaA0;
    case "proportional"
        baseError = sigmaP0;
    case "combined"
        baseError = [sigmaA0/sqrt(2),sigmaP0/sqrt(2)];
end
baseError = min(max(baseError,spec.errorBounds(:,1).'), ...
    spec.errorBounds(:,2).');

factors = cfg.multistart.errorScaleFactors(:);
startsError = nan(nStarts,spec.nError);
for i=1:nStarts
    startsError(i,:) = baseError .* factors(i);
    startsError(i,:) = min(max(startsError(i,:), ...
        spec.errorBounds(:,1).'),spec.errorBounds(:,2).');
end

bank = struct();
bank.theta = startsTheta;
bank.error = startsError;
bank.baseError = baseError;
bank.anchorNative = anchor;
bank.anchorHistoricalEngine = anchorEngine;
bank.anchorPrediction = pred;
bank.anchorSSE_zero_as_number = sum((pred-obs).^2);
end
