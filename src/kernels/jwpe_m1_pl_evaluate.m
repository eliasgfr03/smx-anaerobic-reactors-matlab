function e = jwpe_m1_pl_evaluate(ctx,theta,cfg,phase,onSigma)
%JWPE_M1_PL_EVALUATE Exact shared forward and sigma-v3, no persistence.
theta = double(theta(:).');
assert(nargin==5 && isa(onSigma,'function_handle'));
assert(numel(theta)==5 && all(isfinite(theta)));
if cfg.fixedIndex>0
    assert(theta(cfg.fixedIndex)==cfg.fixedValue);
end
assert(all(theta(cfg.freeIndices)>=cfg.lower & ...
    theta(cfg.freeIndices)<=cfg.upper),'JWPE:P05B:Support','Out-of-support trial.');
if strcmp(ctx.reactor,'CS')
    sim = m1_cs_sim_v1(ctx,theta,m1_cfg_v1());
else
    sim = m1_pf_sim_v1(ctx,theta,m1_cfg_v1());
end
assert(strcmp(sim.model,'M1') && strcmp(sim.reactor,ctx.reactor));
assert(isequal(sim.times_d(:),ctx.auditTimes_d(:)) && max(sim.times_d)==94);
assert(all(isfinite(sim.Cout_SMX)) && all(isfinite(sim.SMX),'all'), ...
    'JWPE:P05B:Forward','Nonfinite internal state or effluent.');
e = struct('theta',theta,'nll',NaN,'eligible',false, ...
    'sigmaProfiled',false,'minimumSMX',sim.minSMX);
if strcmp(ctx.reactor,'PF')
    minimum = pf_min_v2(sim,cfg.invalid.minimumAgreementEpsFactor);
    task.invalid = cfg.invalid;
    classification = pf_class_v2(minimum,task,phase);
    e.minimumLocation=minimum;
    if classification.invalid
        assert(pf_gate_v2(classification.classification,phase,task));
        e.classification=classification.classification;
        return
    end
else
    assert(sim.minSMX>=-2*ctx.settings.AbsTol, ...
        'JWPE:P05B:Forward','Negative CS state exceeds tolerance.');
end
[found,loc]=ismembertol(ctx.observationTimes_d,sim.times_d,1e-12,'DataScale',1);
assert(all(found) && numel(loc)==33 && all(loc>0));
prediction=double(sim.Cout_SMX(loc));
onSigma(); % Charge the profile before entering any inner optimizer.
fit=m1pl_sigma_v3(prediction,ctx,cfg.sigma,[],'');
assert(strcmp(fit.status,'NUMERICALLY_COMPLETE'), ...
    'JWPE:P05B:Sigma','ERROR_MODEL_NUMERICAL_HOLD');
assert(abs(fit.directRecalculationDelta)<=cfg.sigma.likelihood.directTolerance);
map=m1_map_v1(theta,m1_cfg_v1());
assert(map.krev==0 && map.kSigma==theta(2) && map.Fdir==1);
e.nll=fit.nll; e.eligible=true; e.sigmaProfiled=true;
e.classification=fit.classification; e.sigmaA=fit.sigmaA; e.sigmaP=fit.sigmaP;
e.prediction_ug_L=prediction; e.observationTimes_d=ctx.observationTimes_d;
e.auditTimes_d=sim.times_d; e.auditCout_ug_L=sim.Cout_SMX;
e.errorFit=fit; e.phaseIIIExcluded=true; e.maxHorizon_d=94;
end
