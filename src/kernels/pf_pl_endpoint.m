function endpoint=pf_pl_endpoint(cfg,opt,cat,ledger)
%PF_PL_ENDPOINT PF-only wrapper of the validated endpoint schema and guards.
if strcmp(cfg.map,'fixed_ksigma')
    c=cfg; c.map='anchor';
    endpoint=jwpe_pl_m0_endpoint(c,opt,cat,ledger);
    assert(abs(sum(endpoint.theta(2:3))-cfg.fixedValue)<=1e-12);
else
    endpoint=jwpe_pl_m0_endpoint(cfg,opt,cat,ledger);
end
endpoint.reactor='PF';
endpoint.sourceCaseID=cfg.sourceCaseID;
endpoint.sourceProfile=cfg.profile;
end
