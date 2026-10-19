function result=run_gsa_own_v1(b)
%RUN_NATIVE_GSA Reproduce the 18-time M0 analysis for one reactor, manually.
assert(nargin==1 && isequal(b.executeScientific,true),'JWPE:Public:ScienceHeld', ...
    'Explicit scientific confirmation is required.');
data=b.inputs;cfg=data.cfg;key=data.reactor;runID=b.runID;
if ~isfield(data,'sampled') || ~isfield(data,'native')
    data=prepare_gsa_own_v1(cfg,key);
end
assert(~isempty(regexp(runID,'^[A-Za-z0-9_]+$','once')),'JWPE:Public:RunID','Invalid run ID.');
if strcmp(b.mode,'test')
    result=local_short_test(b,data);return
end
folder=b.folder;
assert(~isfolder(folder),'JWPE:Public:Overwrite','Choose a new run ID.');
ctx=b.context; jwpe_own_output_v1(folder);
Y=nan(size(data.native,1),18);history=struct([]);nativeHistory=struct([]);
raw=0;retries=0;budget=cfg.(key).budget;
for i=1:size(Y,1)
 [f,charged,retried]=local_forward(ctx,data.native(i,:),cfg,budget.retryReserve-retries);
 raw=raw+charged;retries=retries+retried;
 assert(raw<=budget.hardTotal && retries<=budget.retryReserve,'JWPE:Public:GSABudget','Budget exhausted.');
 Y(i,:)=f.prediction_ug_L.';
 if mod(i,250)==0
  h=g2_metric(key,i,data.sampled(1:i,:),Y(1:i,:),cfg,cfg.names.sample);
  nh=g2_metric(key,i,data.native(1:i,:),Y(1:i,:),cfg,cfg.names.native);
  history=[history;h];nativeHistory=[nativeHistory;nh]; %#ok<AGROW>
  conv=g2_conv(history,cfg);
  payload=struct('cfg',cfg,'sampled',data.sampled(1:i,:), ...
      'native',data.native(1:i,:),'outputs_ug_L',Y(1:i,:), ...
      'samplingHistory',history,'nativeHistory',nativeHistory,'convergence',conv, ...
      'rawForwards',raw,'retryForwards',retries);
  m1_atomic_v1(fullfile(folder,'latest.mat'),payload,'mat',true);
  fprintf('GSA %s N=%d formalGate=%d\n',key,i,conv(end).globalGate);
  if conv(end).globalGate,break,end
 end
end
assert(conv(end).globalGate,'JWPE:Public:GSAReview','Review convergence; do not auto-extend.');
% Keep the original deterministic Kennard-Stone recheck selection.
selected=gsa_ks_v1(data.sampled(1:i,:),cfg.(key).ranges,cfg.qa.count);
for j=reshape(selected,1,[])
 [f,charged,retried]=local_forward(ctx,data.native(j,:),cfg,budget.retryReserve-retries);
 raw=raw+charged;retries=retries+retried;
 assert(raw<=budget.hardTotal && retries<=budget.retryReserve,'JWPE:Public:GSABudget','Budget exhausted.');
 assert(max(abs(f.prediction_ug_L.'-Y(j,:)))<=cfg.qa.maxAbsDiff_ug_L, ...
     'JWPE:Public:GSARecheck','Independent recheck failed.');
end
result=payload;result.recheckRows=selected;result.rawForwards=raw;result.retryForwards=retries;
result.status='NATIVE_GSA_COMPLETE';result.phaseIIICount=0;result.horizon_d=94;
m1_atomic_v1(fullfile(folder,'result.mat'),result,'mat',false);
end
function [f,charged,retried]=local_forward(ctx,theta,cfg,reserve)
charged=1;retried=0;
try
 f=g2_forward(ctx,theta,cfg);
catch ME
 if reserve<1 || ~gsa_retryable_v1(ME.identifier,ME.message),rethrow(ME),end
 assert(cfg.retry.maxIdenticalRetries==1);
 charged=2;retried=1;
 f=g2_forward(ctx,theta,cfg); % One identical retry; second failure propagates.
end
end

function result=local_short_test(b,data)
% Short interface example; production convergence is never certified here.
cfg=data.cfg;key=b.reactor;ctx=b.context;folder=b.folder;
assert(strcmp(data.reactor,key) && isfield(cfg,'shortTest') && ...
    cfg.shortTest.sampleCount==32 && cfg.shortTest.recheckCount==2 && ...
    cfg.shortTest.maxSeconds>0 && isfinite(cfg.shortTest.maxSeconds), ...
    'JWPE:Public:GSATest','Declare the 32-sample, two-recheck test configuration.');
assert(isequal(size(data.sampled),[32 6]) && isequal(size(data.native),[32 6]) && ...
    isequal(size(data.uniform),[32 6]) && all(isfinite(data.sampled),'all') && ...
    all(isfinite(data.native),'all') && all(data.uniform>=0 & data.uniform<=1,'all'));
assert(cfg.qa.count==2 && cfg.qa.maxAbsDiff_ug_L==1e-12 && ...
    cfg.retry.maxIdenticalRetries==0 && cfg.(key).budget.retryReserve==0 && ...
    cfg.(key).budget.hardTotal==34 && cfg.(key).budget.mcMax==32);
assert(cfg.convergence.firstPossibleStopN==1000 && cfg.persistence.checkpointSize==250);
assert(all(isnan(ctx.forcingData.Cout_ug_L)) && height(ctx.forcingData)==33 && ...
    max(ctx.forcingData.Time_d)==94 && isequal(ctx.outputTimes_d,(5:5:90).'));
mapped=gsa_tri_icdf_v1(data.uniform,cfg.(key).ranges);[native,~]=gsa_map_v1(mapped);
assert(isequal(mapped,data.sampled) && isequal(native,data.native));
jwpe_own_output_v1(folder);
ledger=struct('rawAttempts',0,'rawCompleted',0,'rawFailed',0,'pending',false, ...
    'monteCarloCalls',0,'recheckCalls',0,'hardMax',34,'retries',0);
timer=tic;persist();Y=nan(32,18);history=struct([]);nativeHistory=struct([]);
try
    for i=1:32
        f=forward(data.native(i,:),'MC');Y(i,:)=f.prediction_ug_L.';
        if ismember(i,[16 24 32])
            h=g2_metric(key,i,data.sampled(1:i,:),Y(1:i,:),cfg,cfg.names.sample);
            nh=g2_metric(key,i,data.native(1:i,:),Y(1:i,:),cfg,cfg.names.native);
            history=[history;h];nativeHistory=[nativeHistory;nh]; %#ok<AGROW>
        end
    end
    conv=g2_conv(history,cfg);nativeConv=g2_conv(nativeHistory,cfg);
    assert(~any([conv.globalGate]) && ~any([nativeConv.globalGate]));
    selected=gsa_ks_v1(data.sampled,cfg.(key).ranges,2);deltas=zeros(2,1);
    for j=1:2
        f=forward(data.native(selected(j),:),'RECHECK');
        deltas(j)=max(abs(f.prediction_ug_L.'-Y(selected(j),:)));
        assert(deltas(j)<=cfg.qa.maxAbsDiff_ug_L,'JWPE:Public:GSARecheck','Independent recheck failed.');
    end
    assert(ledger.rawAttempts==34 && ledger.rawCompleted==34 && ledger.rawFailed==0 && ~ledger.pending);
    result=struct('status','TEST_ONLY_GSA_COMPLETE_NOT_CONVERGENCE','testOnly',true, ...
        'reactor',key,'cfg',cfg,'uniform',data.uniform,'sampled',data.sampled,'native',data.native, ...
        'outputs_ug_L',Y,'samplingHistory',history,'nativeHistory',nativeHistory, ...
        'convergence',conv,'nativeConvergence',nativeConv,'recheckRows',selected,'recheckDeltas',deltas, ...
        'rawLedger',ledger,'rawForwards',ledger.rawAttempts,'retryForwards',0, ...
        'productionCheckpointsReached',false,'scientificConvergenceCertified',false, ...
        'phaseIIICount',0,'horizon_d',94,'outputTimes_d',cfg.times.all_d,'identity',b.identity);
    m1_atomic_v1(fullfile(folder,'configuration.mat'),cfg,'mat',false);
    m1_atomic_v1(fullfile(folder,'result.mat'),result,'mat',false);
    T=array2table(Y,'VariableNames',cellstr(compose('day_%02d',cfg.times.all_d)));
    m1_atomic_v1(fullfile(folder,'outputs.csv'),T,'table',false);
    T=array2table(nativeHistory(end).srrc,'VariableNames',cellstr(cfg.names.native));
    T=addvars(T,cfg.times.all_d(:),'Before',1,'NewVariableNames','Time_d');T.R2_rank=nativeHistory(end).r2Time;
    m1_atomic_v1(fullfile(folder,'native_srrc.csv'),T,'table',false);
    summary=struct('status',result.status,'testOnly',true,'reactor',key,'samples',32, ...
        'outputsPerSample',18,'rawForwards',ledger.rawAttempts,'rechecks',2, ...
        'maxRecheckDelta',max(deltas),'scientificConvergenceCertified',false, ...
        'productionCheckpointsReached',false);
    m1_atomic_v1(fullfile(folder,'summary.json'),jsonencode(summary),'text',false);
    jwpe_capacity_manifest(folder,{'configuration.mat','result.mat','ledger.mat', ...
        'outputs.csv','native_srrc.csv','summary.json'});
catch ME
    stop=struct('status','STOP_NO_RETRY','identifier',ME.identifier,'message',ME.message,'retryAuthorized',false);
    m1_atomic_v1(fullfile(folder,'STOP.json'),jsonencode(stop),'text',false);rethrow(ME)
end
    function f=forward(theta,phase)
        assert(toc(timer)<cfg.shortTest.maxSeconds && ledger.rawAttempts<34 && ~ledger.pending, ...
            'JWPE:Public:GSABudget','Short-run time or raw-forward limit reached.');
        ledger.rawAttempts=ledger.rawAttempts+1;ledger.pending=true;
        if strcmp(phase,'MC'),ledger.monteCarloCalls=ledger.monteCarloCalls+1;
        else,ledger.recheckCalls=ledger.recheckCalls+1;end
        persist();
        try
            f=g2_forward(ctx,theta,cfg);ledger.rawCompleted=ledger.rawCompleted+1;ledger.pending=false;persist();
        catch ME
            ledger.rawFailed=ledger.rawFailed+1;ledger.pending=false;persist();rethrow(ME)
        end
    end
    function persist()
        m1_atomic_v1(fullfile(folder,'ledger.mat'),ledger,'mat',true);
    end
end
