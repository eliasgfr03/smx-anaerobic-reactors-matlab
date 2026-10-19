function [logPrior,detail] = tb_prior_v1(physical,cfg)
%TB_PRIOR_V1 Physical prior core without legacy log-sigma Jacobians.

physical = double(physical(:).');
if ~tb_support_v1(physical,cfg)
    logPrior = -Inf;
else
    logPrior = -0.5*((physical(1)-cfg.prior.KdMean)/cfg.prior.KdSD)^2- ...
        0.5*(physical(6)/cfg.prior.sigmaAScale)^2- ...
        0.5*(physical(7)/cfg.prior.sigmaPScale)^2;
end
detail = struct('insideSupport',isfinite(logPrior), ...
    'containsLegacyEtaJacobian',false,'logPriorPhys',logPrior);
end
