function out=tb_predict_v1(mechanistic,data)
%TB_PREDICT_V1 CS adapter: same engine/grid, bounded memory instead of disk.
assert(isfield(data,'confirmScience') && isequal(data.confirmScience,true), ...
    'JWPE:Public:ScienceHeld','Scientific calls are held.');
[hit,value,key]=jwpe_mcmc_memory('probe','prediction',mechanistic);
if hit,out=value;out.cacheHit=true;out.rawIncrement=0;return,end
started=tic;sim=m1_cs_sim_v1(data.ctx,mechanistic,m1_cfg_v1());
assert(strcmp(sim.model,'M1') && strcmp(sim.reactor,'CS') && ...
    isequal(sim.times_d(:),data.ctx.auditTimes_d(:)) && max(sim.times_d)==94 && ...
    all(isfinite(sim.Cout_SMX)) && all(isfinite(sim.SMX),'all') && ...
    sim.minSMX>=-2*data.cfg.solver.AbsTol,'JWPE:TB:ForwardFailure','Invalid CS forward.');
[found,loc]=ismembertol(data.ctx.observationTimes_d,sim.times_d,1e-12,'DataScale',1);
assert(all(found) && numel(loc)==33 && all(loc>0));
out=struct('prediction',double(sim.Cout_SMX(loc)),'cacheHit',false, ...
    'rawIncrement',1,'key',key,'elapsed_s',toc(started));
jwpe_mcmc_memory('put','prediction',mechanistic,out);
end
