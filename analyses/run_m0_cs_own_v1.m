function endpoint = run_m0_cs_own_v1(b)
%RUN_PL_M0 Reexecute ONE recorded CS native-M0 conditional/anchor search.
% Exact case IDs/settings are available from jwpe_pl_m0_config('CS').
catalogue=b.catalogue; cfg=b.caseConfig;
assert(~isempty(cfg),'JWPE:PL:Config','Specify one recorded case.');
identity=b.identity;
out=jwpe_own_output_v1(b.folder);
reserved=struct('status','RESERVED_NOT_COMPLETED','caseID',cfg.id, ...
    'rawAttempts',0,'scientificContextID',catalogue.contextID);
jwpe_run_write(out,'ledger.json',jsonencode(reserved),'text',false);
try
    [ctx,core]=m0_cs_context_own_v1(b,cfg,@record_ledger);
    [problem,options]=jwpe_pl_m0_problem(cfg,ctx,core,out);
    opt=jwpe_pl_m0_run_surrogate(problem,options);
    ledger=ctx.getRawLedger();
    endpoint=jwpe_pl_m0_endpoint(cfg,opt,catalogue,ledger);
    payload=struct('endpoint',endpoint,'caseConfig',cfg,'optimizer',opt,'identity',identity);
    jwpe_run_write(out,'result.mat',payload,'mat',false);
    jwpe_run_write(out,'endpoint.json',jsonencode(endpoint),'text',false);
    jwpe_run_write(out,'ledger.json',jsonencode(ledger),'text',true);
    jwpe_capacity_manifest(out,{'result.mat','endpoint.json','ledger.json'});
    assert(~strcmp(endpoint.status,'ANCHOR_CHALLENGE'),'JWPE:PL:Anchor', ...
        'Anchor challenge saved. STOP; do not promote anchor or start another search.');
catch ME
    failure=struct('status','STOP_NO_RETRY','caseID',cfg.id, ...
        'errorID',ME.identifier,'message',ME.message);
    jwpe_run_write(out,'stop.json',jsonencode(failure),'text',false);
    rethrow(ME)
end
    function record_ledger(ledger)
        jwpe_run_write(out,'ledger.json',jsonencode(ledger),'text',true);
    end
end
