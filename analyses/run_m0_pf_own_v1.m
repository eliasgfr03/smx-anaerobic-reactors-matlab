function endpoint=run_m0_pf_own_v1(b)
%RUN_PL_M0_PF One source-bound M0 PF case, never an automatic full campaign.
assert(nargin==1 && isequal(b.executeScientific,true),'JWPE:Public:ScienceHeld', ...
    'PF M0 scientific execution requires explicit confirmation.');
cat=b.catalogue; cfg=b.caseConfig; identity=b.identity;
out=jwpe_own_output_v1(b.folder);
try
    [ctx,core]=m0_pf_context_own_v1(b,cfg,@record);
    fast=@(x)pf_pl_evaluate(x,cfg,ctx,core,false);
    recheck=@(x)pf_pl_evaluate(x,cfg,ctx,core,true);
    [initial,seedStats]=pf_pl_prepare_seeds(cfg,fast,recheck,cat.anchor.nll);
    if seedStats.earlyChallenge
        jwpe_run_write(out,'anchor_challenge.json',jsonencode(seedStats),'text',false);
        error('PFPort:Anchor','Confirmed pre-search anchor challenge; STOP without optimizer.');
    end
    problem=struct('name',['PF_M0_' cfg.id],'lbPhysical',cfg.lb(:).','ubPhysical',cfg.ub(:).', ...
        'parameterNames',cfg.names,'evaluateFcn',fast,'recheckFcn',recheck, ...
        'constraintFcnPhysical',[],'initialPointsPhysical',[], ...
        'initialPointsNormalized',initial,'objectiveLimit',[],'outputDir',out,'isExpensive',true);
    options=cfg.config; options.checkpointPolicy='never';
    options.maxFunctionEvaluations=seedStats.remainingOptimizerCap;
    if strcmp(cfg.seedMode,'normalized_explicit_inputs')
        options.maxFunctionEvaluations=cfg.config.maxFunctionEvaluations;
    end
    opt=jwpe_pl_m0_run_surrogate(problem,options);
    ledger=ctx.getRawLedger(); endpoint=pf_pl_endpoint(cfg,opt,cat,ledger);
    payload=struct('endpoint',endpoint,'caseConfig',cfg,'optimizer',opt, ...
        'seedStatistics',seedStats,'identity',identity);
    jwpe_run_write(out,'result.mat',payload,'mat',false);
    jwpe_run_write(out,'endpoint.json',jsonencode(endpoint),'text',false);
    jwpe_run_write(out,'ledger.json',jsonencode(ledger),'text',true);
    jwpe_capacity_manifest(out,{'result.mat','endpoint.json','ledger.json'});
    assert(strcmp(endpoint.status,'PASS'),'PFPort:Anchor','Anchor challenge saved; STOP/review.');
catch ME
    stop=struct('status','STOP_NO_RETRY','caseID',cfg.id,'identifier',ME.identifier,'message',ME.message);
    jwpe_run_write(out,'stop.json',jsonencode(stop),'text',false);
    rethrow(ME)
end
    function record(ledger)
        jwpe_run_write(out,'ledger.json',jsonencode(ledger),'text',true);
    end
end
