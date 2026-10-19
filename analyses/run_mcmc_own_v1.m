function result=run_mcmc_own_v1(b)
%JWPE_MCMC_SESSION Exact saved RAM/MH state; no interrupted-block replay.
cfg=b.config;key=cfg.reactor;runID=b.runID;mode=b.action;sweepLimit=b.sweepLimit;
assert(~isempty(regexp(runID,'^[A-Za-z0-9_]+$','once')),'JWPE:Public:RunID','Invalid run ID.');
validateattributes(sweepLimit,{'numeric'},{'scalar','positive'});
assert(isinf(sweepLimit) || (isfinite(sweepLimit) && sweepLimit==fix(sweepLimit) && ...
 mod(sweepLimit,cfg.sampler.checkpointEvery)==0),'JWPE:Public:ResumeHeld','Pause only at complete checkpoints.');
codeHash=b.identity.codeHash;folder=b.folder;
if strcmp(mode,'start')
 assert(~isfolder(folder),'JWPE:Public:Overwrite','Choose a new run ID.');mkdir(folder);
 m1_atomic_v1(fullfile(folder,'run_config.mat'),struct('cfg',cfg,'codeHash',codeHash),'mat',false);
else
 assert(strcmp(mode,'resume') && isfolder(folder),'JWPE:Public:ResumeHeld','No resumable run.');
 q=load(fullfile(folder,'run_config.mat'),'payload');
 assert(isequaln(q.payload.cfg,cfg) && strcmp(q.payload.codeHash,codeHash), ...
  'JWPE:Public:ResumeHeld','Configuration or runtime changed.');
 assert(~isfile(fullfile(folder,'summary.mat')),'JWPE:Public:ResumeHeld','Completed run is not repeated.');
end
ctx=b.context;data=struct('cfg',cfg,'ctx',ctx,'confirmScience',true);
oldRng=rng;restoreRng=onCleanup(@()rng(oldRng));assert(isa(restoreRng,'onCleanup'));
initial=b.initial;
n=cfg.sampler.productionRows;total=cfg.sampler.ramSweeps+n;consumed=0;
chains=cell(1,4);raw=zeros(1,4);targets=raw;
for c=1:4
 chainDir=fullfile(folder,sprintf('chain_%02d',c));production=fullfile(chainDir,'production.mat');
 if isfile(production)
  q=load(production,'payload');p=q.payload;
  assert(strcmp(p.codeHash,codeHash) && p.rows==n && p.chain==c && strcmp(p.reactor,key));
  boundary=jwpe_mcmc_boundary('load',chainDir);
  assert(boundary.sweep==total && isequaln(boundary.physical,p.physical) && ...
   isequaln(boundary.sampled,p.sampled) && boundary.rawForwards==p.rawForwards && ...
   boundary.targetCalls==p.targetCalls,'JWPE:Public:ResumeHeld','Completed chain does not match boundary.');
  rootChain=fullfile(folder,sprintf('chain_%02d.mat',c));
  if ~isfile(rootChain),m1_atomic_v1(rootChain,p,'mat',false);
  else
   existing=load(rootChain,'payload');assert(isequaln(existing.payload,p),'JWPE:Public:ResumeHeld','Changed complete chain.');
  end
  chains{c}=p.physical;raw(c)=p.rawForwards;targets(c)=p.targetCalls;continue
 end
 jwpe_mcmc_memory('reset','','');physical=zeros(n,7);sampled=zeros(n,7);
 if isfolder(chainDir)
  p=jwpe_mcmc_boundary('load',chainDir);
  assert(isequaln(p.cfg,cfg) && strcmp(p.codeHash,codeHash) && p.chain==c && strcmp(p.reactor,key));
  rng(p.rngState);current=p.current;Sm=p.Sm;Se=p.Se;sweepDone=p.sweep;
  rows=max(0,sweepDone-cfg.sampler.ramSweeps);
  assert(isequal(size(p.physical),[rows 7]) && isequal(size(p.sampled),[rows 7]));
  physical(1:rows,:)=p.physical;sampled(1:rows,:)=p.sampled;
  raw(c)=p.rawForwards;targets(c)=p.targetCalls;jwpe_mcmc_memory('restore','','',p.cache);
 else
  mkdir(chainDir);jwpe_mcmc_boundary('begin',chainDir);
  if strcmp(key,'CS'),rng(initial.rng{c});else,rng(cfg.rng.fullSeeds(c),'twister');end
  z=initial.sampled(c,:);
  if strcmp(key,'CS')
   pred=tb_predict_v1(initial.physical(c,1:5),data);
   current=tb_like_v1(z,pred.prediction,ctx,cfg);current.prediction=pred.prediction;current.cacheKey=pred.key;
  else
   pred=pftb_predict_v1(initial.physical(c,1:5),data);assert(pred.valid);
   current=pftb_like_v1(z,pred.prediction,data);current.predictionKey=pred.key;
  end
  raw(c)=pred.rawIncrement;targets(c)=1;Sm=chol(initial.Qm0);Se=chol(initial.Qe0);sweepDone=0;
  checkpoint(0,'INITIAL');
 end
 for sweep=sweepDone+1:total
  if mod(sweep-1,cfg.sampler.checkpointEvery)==0,jwpe_mcmc_boundary('begin',chainDir);end
  adapt=sweep<=cfg.sampler.ramSweeps;if adapt,stage='RAM';else,stage='MH';end
  if strcmp(key,'CS')
   [current,Sm,rm]=tb_step_v1(current,'MECHANISTIC',Sm,adapt,sweep,data,stage,sweep);
   [current,Se,re]=tb_step_v1(current,'ERROR',Se,adapt,sweep,data,stage,sweep);
  else
   [current,Sm,rm]=pftb_step_v1(current,'MECHANISTIC',Sm,adapt,sweep,data,stage,sweep,1);
   [current,Se,re]=pftb_step_v1(current,'ERROR',Se,adapt,sweep,data,stage,sweep,1);
  end
  raw(c)=raw(c)+rm.rawIncrement+re.rawIncrement;targets(c)=targets(c)+rm.targetIncrement+re.targetIncrement;
  assert(re.rawIncrement==0 && raw(c)<=cfg.maximumRawPerChain,'JWPE:Public:MCMCBudget','Budget exceeded.');
  if ~adapt,row=sweep-cfg.sampler.ramSweeps;physical(row,:)=current.physical;sampled(row,:)=current.z;end
  consumed=consumed+1;
  if mod(sweep,cfg.sampler.checkpointEvery)==0 || sweep==total
   checkpoint(sweep,stage);
   if sweep<total && consumed>=sweepLimit
    result=struct('status','PAUSED_AT_COMPLETE_BOUNDARY','reactor',key,'chain',c,'sweep',sweep);return
   end
  end
 end
 chains{c}=physical;
 p=struct('reactor',key,'chain',c,'physical',physical,'sampled',sampled,'codeHash',codeHash, ...
  'warmupExcluded',true,'thinning',1,'rows',n,'rawForwards',raw(c),'targetCalls',targets(c));
 m1_atomic_v1(production,p,'mat',false);
 m1_atomic_v1(fullfile(folder,sprintf('chain_%02d.mat',c)),p,'mat',false);
 if c<4 && consumed>=sweepLimit
  result=struct('status','PAUSED_BETWEEN_CHAINS','reactor',key,'chain',c);return
 end
end
diagnostics=tb_diag_v1(chains,cfg,'NEW_INDEPENDENT_RUN');
result=struct('reactor',key,'rowsPerChain',n,'chains',4,'diagnostics',diagnostics, ...
 'rawForwards',sum(raw),'targetCalls',sum(targets),'phaseIIICount',0,'horizon_d',94, ...
 'pooling',false,'certified',diagnostics.pass);
m1_atomic_v1(fullfile(folder,'summary.mat'),result,'mat',false);
jwpe_closed_source('close',folder,{'chain_01.mat','chain_02.mat','chain_03.mat','chain_04.mat','summary.mat'});
if ~diagnostics.pass,warning('JWPE:Public:MCMCReview','No automatic extension or posterior promotion.');end
 function checkpoint(sweep,stage)
  rows=max(0,sweep-cfg.sampler.ramSweeps);[~,cache]=jwpe_mcmc_memory('snapshot','','');
  p=struct('reactor',key,'chain',c,'sweep',sweep,'cfg',cfg,'codeHash',codeHash, ...
   'current',current,'Sm',Sm,'Se',Se,'rngState',rng,'cache',cache, ...
   'physical',physical(1:rows,:),'sampled',sampled(1:rows,:), ...
   'rawForwards',raw(c),'targetCalls',targets(c),'stage',stage);
  jwpe_mcmc_boundary('commit',chainDir,p);
  fprintf('MCMC %s chain=%d %s sweep=%d raw=%d\n',key,c,stage,sweep,raw(c));
 end
end
