function spec = JWPE_OEM_model_spec_v1_3(modelName,cfg)

modelName = lower(string(modelName));
spec = struct();
spec.name = char(modelName);

switch modelName
    case "additive"
        spec.label = 'Additive Gaussian';
        spec.errorNames = {'sigmaA'};
        spec.errorUnits = {'ug/L'};
        spec.errorBounds = cfg.error.sigmaA_bounds;
    case "proportional"
        spec.label = 'Proportional Gaussian';
        spec.errorNames = {'sigmaP'};
        spec.errorUnits = {'-'};
        spec.errorBounds = cfg.error.sigmaP_bounds;
    case "combined"
        spec.label = 'Additive + proportional Gaussian';
        spec.errorNames = {'sigmaA','sigmaP'};
        spec.errorUnits = {'ug/L','-'};
        spec.errorBounds = [cfg.error.sigmaA_bounds;cfg.error.sigmaP_bounds];
    otherwise
        error('Unknown observation model: %s',modelName);
end

spec.nError = numel(spec.errorNames);
spec.nMean = 6;
spec.nEstimated = spec.nMean + spec.nError;
end
