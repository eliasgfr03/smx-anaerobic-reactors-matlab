function current=pftb_like_v1(z,prediction,data)
%PFTB_LIKE_V1 Same transformed target through the exact shared CS target core.
assert(isfield(data,'confirmScience') && isequal(data.confirmScience,true), ...
    'JWPE:Public:ScienceHeld','Scientific calls are held.');
[hit,value,key]=jwpe_mcmc_memory('probe','target',z);
if hit,current=value;current.targetCacheHit=true;return,end
current=tb_like_v1(z,prediction,data.ctx,data.cfg);
current.prediction=double(prediction(:));
current.targetCacheHit=false;current.targetKey=key;
jwpe_mcmc_memory('put','target',z,current);
end
