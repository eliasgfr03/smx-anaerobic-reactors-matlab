function score=run_holdout_own_v1(b)
%RUN_SMX_TEMPORAL_HOLDOUT Same frozen joint vectors, new holdout innovations.
assert(nargin==1 && isequal(b.executeScientific,true),'JWPE:Public:ScienceHeld','Holdout execution held.');
reactor=char(upper(string(b.reactor)));assert(ismember(reactor,{'CS','PF'}));
folder=jwpe_own_output_v1(b.folder);cfg=b.config;ctx=b.context;selected=b.selected;reference=b.reference;
assert(isequaln(reference.selected,selected));
mu=zeros(500,numel(ctx.fullTimes_d));raw=0;keys=strings(0,1);values=zeros(0,size(mu,2));
for d=1:500
 theta=selected{d,{'Kd','kb','kG','tinf','Ai'}};key=string(m1_hash_v1(typecast(theta,'uint8'),'bytes'));
 hit=find(keys==key,1);
 if ~isempty(hit),mu(d,:)=values(hit,:);else
  assert(raw<500);sim=p3v_sim_v1(ctx,theta,cfg);mu(d,:)=sim.Cout_SMX.';raw=raw+1;
  keys(end+1,1)=key;values(end+1,:)=mu(d,:); %#ok<AGROW>
 end
 prefix=ctx.fullTimes_d<=94;assert(isequal(ctx.fullTimes_d(prefix),reference.times_d));
 delta=abs(mu(d,prefix)-reference.mu(d,:));
 tolerance=2*ctx.settings.AbsTol+64*eps(max(1,abs(reference.mu(d,:))));
 assert(all(delta<=tolerance),'JWPE:Public:Prefix','Published prefix-equivalence guard failed.');
 if mod(d,50)==0,m1_atomic_v1(fullfile(folder,'latest.mat'),struct('completed',d,'mu',mu(1:d,:),'rawForwards',raw),'mat',true);end
end
phase3=ctx.fullTimes_d>94;
[yrep,pCens,errorRng]=jwpe_eval_noise(mu(:,phase3),selected,cfg.errorSeed.(reactor),cfg.lod);
core=struct('reactor',reactor,'mu',mu,'times_d',ctx.fullTimes_d,'selected',selected,'pCens',pCens,'errorRng',errorRng,'rawForwards',raw);
m1_atomic_v1(fullfile(folder,'prediction.mat'),core,'mat',false);
gate=jwpe_prediction_gate('close',folder);jwpe_prediction_gate('require',gate);
data=readtable(b.responseFile);use=data.Time_d>94;
rawResponse=data.Cout_ug_L(use);validation=p3v_math_v1('zerotolod',rawResponse,cfg.lod);
holdout=table(data.Time_d(use),rawResponse,validation,rawResponse==0, ...
 'VariableNames',{'Time_d','RawCout_ug_L','ValidationCout_ug_L','RawZeroMappedToLOD'});
bound=struct('meanBand',reference.meanBand,'predBand',reference.predictiveBand);
core.yrep=yrep;score=p3d_score_v2(core,holdout,bound,cfg);
m1_atomic_v1(fullfile(folder,'score.mat'),score,'mat',false);
m1_atomic_v1(fullfile(folder,'result.mat'),core_without_replicates(core),'mat',false);
jwpe_closed_source('close',folder,{'result.mat','prediction.mat','score.mat'});
end
function saved=core_without_replicates(core)
saved=rmfield(core,'yrep');
end
