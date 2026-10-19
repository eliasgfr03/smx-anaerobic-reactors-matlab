function [yrep,pCens,receipt]=jwpe_eval_noise(mu,selected,seed,lod)
%JWPE_EVAL_NOISE Exact accepted draw/replicate/time RNG ordering.
assert(size(mu,1)==500 && height(selected)==500);
nT=size(mu,2);stream=RandStream('mt19937ar','Seed',seed);initial=stream.State;
yrep=zeros(500,20,nT);pCens=zeros(500,nT);
for d=1:500
 sigma=ppu_math_v1('sigma',mu(d,:),selected.sigmaA(d),selected.sigmaP(d));
 z=randn(stream,20*nT,1);z=reshape(z,nT,20).';
 yrep(d,:,:)=mu(d,:)+sigma.*z;
 pCens(d,:)=ppu_math_v1('pcens',mu(d,:),sigma,lod);
end
receipt=struct('seed',seed,'initialState',initial,'finalState',stream.State, ...
    'ordering','ChainID,StratumID,ReplicateID,TimeID','replicatesPerDraw',20);
end
