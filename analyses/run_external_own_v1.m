function score=run_external_own_v1(b)
%RUN_EXTERNAL_SMX Separate no-refit mean-response transfer per external reactor.
assert(nargin==1 && isequal(b.executeScientific,true),'JWPE:Public:ScienceHeld','External transfer held.');
study=b.study;reactor=b.reactor;
folder=jwpe_own_output_v1(b.folder);ctx=b.context;cfg=b.config;selected=b.selected;responseFile=b.responseFile;
theta=selected{426,{'Kd','kb','kG','tinf','Ai'}};zero=zeros(69,1);
if strcmp(study,'CARNEIRO')
 stop=cfg.sentinel.stop_d;fill=cfg.system.(reactor).firstCin_ug_L;
 a=ev1_sim_v1(ctx,theta,zero,cfg,stop);b=ev1_sim_v1(ctx,theta,repmat(fill,69,1),cfg,stop);
else
 assert(strcmp(study,'SOEIRA'));stop=49;fill=cfg.input.firstCin;
 a=ev2_sim_v1(ctx,theta,zero,cfg,stop);b=ev2_sim_v1(ctx,theta,repmat(fill,69,1),cfg,stop);
end
delta=abs(a.Cout_SMX(end)-b.Cout_SMX(end));tolerance=2*ctx.settings.AbsTol+64*eps(max(1,abs(a.Cout_SMX(end))));
m1_atomic_v1(fullfile(folder,'sentinel.mat'),struct('absoluteDifference',delta,'tolerance',tolerance,'rawForwards',2),'mat',false);
assert(delta<=tolerance,'JWPE:Public:Sentinel','Initialization sentinel failed; no expansion.');
mu=zeros(500,numel(ctx.auditTimes_d));raw=2;keys=strings(0,1);values=zeros(0,size(mu,2));
for d=1:500
 theta=selected{d,{'Kd','kb','kG','tinf','Ai'}};key=string(m1_hash_v1(typecast(theta,'uint8'),'bytes'));hit=find(keys==key,1);
 if isempty(hit)
  assert(raw<502);
  if strcmp(study,'CARNEIRO')
   sim=ev1_sim_v1(ctx,theta,zero,cfg,ctx.end_d);
  else
   sim=ev2_sim_v1(ctx,theta,zero,cfg,ctx.end_d);assert(sim.finite && sim.solverPass && sim.negativePass);
  end
  assert(isequal(sim.times_d,ctx.auditTimes_d));mu(d,:)=sim.Cout_SMX.';raw=raw+1;
  keys(end+1,1)=key;values(end+1,:)=mu(d,:); %#ok<AGROW>
 else
  mu(d,:)=values(hit,:);
 end
 if mod(d,50)==0,m1_atomic_v1(fullfile(folder,'latest.mat'),struct('completed',d,'mu',mu(1:d,:),'rawForwards',raw),'mat',true);end
end
core=struct('reactor',reactor,'mu',mu,'times_d',ctx.auditTimes_d,'selected',selected,'rawForwards',raw);
m1_atomic_v1(fullfile(folder,'prediction.mat'),core,'mat',false);
gate=jwpe_prediction_gate('close',folder);jwpe_prediction_gate('require',gate);
response=jwpe_eval_io('readtable',responseFile);
if strcmp(study,'CARNEIRO'),response=response(string(response.Reactor)==reactor,:);end
score=jwpe_external_score(core,response);m1_atomic_v1(fullfile(folder,'score.mat'),score,'mat',false);
end
