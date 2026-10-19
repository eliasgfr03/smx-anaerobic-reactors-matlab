function [Snew,Qnew] = tb_ram_update_v1(S,u,alpha,n,cfg)
%TB_RAM_UPDATE_V1 Exact upper-factor RAM recursion for one block.

u = double(u(:).'); S = double(S);
normU = norm(u);
assert(isfinite(normU) && normU>0 && all(isfinite(S),'all') && ...
    isscalar(n) && n>=1,'JWPE:TB:RAM','Invalid RAM update input.');
unitU = u/normU;
eta = (n+1)^(-cfg.sampler.etaParam);
M = eye(numel(u))+eta*(alpha-cfg.sampler.alphaTarget)*(unitU.'*unitU);
Qnew = S.'*M*S; Qnew = (Qnew+Qnew.')/2;
[Snew,pd] = chol(Qnew);
assert(pd==0 && all(isfinite(Snew),'all'),'JWPE:TB:RAM', ...
    'Direct RAM Cholesky update failed.');
end
