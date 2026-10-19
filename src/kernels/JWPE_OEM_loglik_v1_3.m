function [nll,detail] = JWPE_OEM_loglik_v1_3(pred,obs,modelName,errorPars,lod)
%JWPE_OEM_LOGLIK_V1_3 Complete Gaussian likelihood with left-censoring.
%
% INPUTS
%   pred      model predictions (ug/L)
%   obs       stored observations; zero means y < LOD
%   modelName additive | proportional | combined
%   errorPars additive:     sigmaA
%             proportional: sigmaP
%             combined:     [sigmaA sigmaP]
%   lod       detection threshold in ug/L
%
% IMPORTANT
% Censored observations contribute log P(Y < LOD | prediction, sigma).
% They are not replaced by LOD or by zero.

pred = pred(:);
obs = obs(:);
assert(numel(pred)==numel(obs),'Prediction/observation length mismatch.');
assert(isscalar(lod) && isfinite(lod) && lod>0,'LOD must be positive.');

modelName = lower(string(modelName));
errorPars = errorPars(:);
valid = all(isfinite(pred)) && all(isfinite(obs)) && all(isfinite(errorPars));

switch modelName
    case "additive"
        assert(numel(errorPars)==1,'Additive model expects sigmaA.');
        sigmaA = errorPars(1);
        valid = valid && sigmaA>0;
        sigma = repmat(sigmaA,size(pred));
    case "proportional"
        assert(numel(errorPars)==1,'Proportional model expects sigmaP.');
        sigmaP = errorPars(1);
        % No epsilon/floor is inserted into the scientific likelihood.
        % If the mean prediction is nonpositive, pure proportional error is
        % mathematically incompatible with this parameter vector.
        valid = valid && sigmaP>0 && all(pred>0);
        sigma = sigmaP .* pred;
    case "combined"
        assert(numel(errorPars)==2, ...
            'Combined model expects [sigmaA sigmaP].');
        sigmaA = errorPars(1);
        sigmaP = errorPars(2);
        valid = valid && sigmaA>0 && sigmaP>0;
        sigma = sqrt(sigmaA.^2 + (sigmaP.*pred).^2);
    otherwise
        error('Unknown observation model: %s',modelName);
end

valid = valid && all(isfinite(sigma)) && all(sigma>0);
if ~valid
    nll = Inf;
    detail = local_empty_detail(pred,obs);
    detail.valid = false;
    return
end

isCensored = obs<=0;
isQuantified = ~isCensored;
logContrib = nan(size(obs));
stdResidual = nan(size(obs));

% Quantified points: full Gaussian log-density, including log(sigma_i).
if any(isQuantified)
    zq = (obs(isQuantified)-pred(isQuantified))./sigma(isQuantified);
    logContrib(isQuantified) = -0.5*log(2*pi) - ...
        log(sigma(isQuantified)) - 0.5*zq.^2;
    stdResidual(isQuantified) = zq;
end

% Left-censored points: log Phi((LOD-mu_i)/sigma_i).
zLod = (lod-pred)./sigma;
logCdf = local_log_normcdf(zLod);
if any(isCensored)
    logContrib(isCensored) = logCdf(isCensored);
end

nll = -sum(logContrib);
if ~isfinite(nll)
    nll = Inf;
end

% Probability that a replicate would fall below the LOD. This is useful for
% predictive calibration diagnostics at every observation time.
censorProbability = exp(max(logCdf,log(realmin('double'))));

rawResidual = obs-pred;
detail = struct();
detail.valid = isfinite(nll);
detail.sigma = sigma;
detail.logLikContribution = logContrib;
detail.stdResidual = stdResidual;
detail.rawResidualStored = rawResidual;
detail.zLOD = zLod;
detail.logCensorProbability = logCdf;
detail.censorProbability = censorProbability;
detail.isCensored = isCensored;
detail.isQuantified = isQuantified;
detail.logLik = -nll;

end

function logPhi = local_log_normcdf(z)
% Numerically stable log(Phi(z)). For the far-left tail, use erfcx:
% Phi(z) = 0.5*exp(-z^2/2)*erfcx(-z/sqrt(2)), z<0.
z = z(:);
logPhi = zeros(size(z));
left = z < -5;
if any(left)
    x = -z(left)./sqrt(2);
    logPhi(left) = log(0.5) + log(erfcx(x)) - 0.5*z(left).^2;
end
if any(~left)
    p = 0.5 .* erfc(-z(~left)./sqrt(2));
    logPhi(~left) = log(p);
end
end

function detail = local_empty_detail(pred,obs)
detail = struct('valid',false,'sigma',nan(size(pred)), ...
    'logLikContribution',nan(size(obs)), ...
    'stdResidual',nan(size(obs)), ...
    'rawResidualStored',obs-pred, ...
    'zLOD',nan(size(obs)), ...
    'logCensorProbability',nan(size(obs)), ...
    'censorProbability',nan(size(obs)), ...
    'isCensored',obs<=0,'isQuantified',obs>0,'logLik',-Inf);
end
