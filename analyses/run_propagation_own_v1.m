function result=run_propagation_own_v1(b)
%RUN_SMX_PROPAGATION Manual 500-draw Phase-I-II propagation; no automatic next stage.
assert(nargin==1 && isequal(b.executeScientific,true),'JWPE:Public:ScienceHeld','Scientific propagation held.');
reactor=char(upper(string(b.reactor)));assert(ismember(reactor,{'CS','PF'}));
folder=jwpe_own_output_v1(b.folder);cfg=b.config;selected=b.selected;ctx=b.context;
grid=ppu_grid_v1(ctx,cfg);mu=zeros(500,numel(grid.times_d));raw=0;
keys=strings(0,1);values=zeros(0,size(mu,2));
for d=1:500
 theta=selected{d,{'Kd','kb','kG','tinf','Ai'}};
 [hit,value,~,key]=ppu_cache_v1(reactor,theta,[reactor '|INDEPENDENT_PPU_H94'],keys,values);
 if hit,mu(d,:)=value;else
  assert(raw<500);if strcmp(reactor,'CS'),sim=m1_cs_sim_v1(ctx,theta,m1_cfg_v1());
  else,sim=m1_pf_sim_v1(ctx,theta,m1_cfg_v1());end
  assert(isequal(sim.times_d,grid.times_d) && sim.minSMX>=-2*ctx.settings.AbsTol);
  mu(d,:)=sim.Cout_SMX.';raw=raw+1;keys(end+1,1)=string(key);values(end+1,:)=mu(d,:); %#ok<AGROW>
 end
 if mod(d,50)==0
  payload=struct('completed',d,'mu',mu(1:d,:),'rawForwards',raw,'selected',selected);
  m1_atomic_v1(fullfile(folder,'latest.mat'),payload,'mat',true);
 end
end
[yrep,pCens,errorRng]=jwpe_eval_noise(mu,selected,cfg.(reactor).errorSeed,cfg.lod);
[meanBand,predBand]=jwpe_eval_bands(grid.times_d,mu,yrep);
result=struct('reactor',reactor,'mu',mu,'times_d',grid.times_d,'selected',selected, ...
 'meanBand',meanBand,'predictiveBand',predBand,'pCensDraw',pCens,'errorRng',errorRng, ...
 'rawForwards',raw,'logicalDraws',500,'phaseIIICount',0,'horizon_d',94);
m1_atomic_v1(fullfile(folder,'result.mat'),result,'mat',false);
m1_atomic_v1(fullfile(folder,'mean_band.csv'),meanBand,'table',false);
m1_atomic_v1(fullfile(folder,'pred_band.csv'),predBand,'table',false);
jwpe_closed_source('close',folder,{'result.mat','mean_band.csv','pred_band.csv'});
% Replicates can be reconstructed exactly from mu, selected parameters and RNG.
end
