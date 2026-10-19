function S = m1_pf_jpat_v1(settings)
%M1_PF_JPAT_V1 Conservative sparsity pattern for the 69-state M1 PF ODE.

ni = settings.node_count-2;
assert(ni==69,'JWPE:M1:Dimension','PF requires 69 differential nodes.');
S = spones(spdiags(ones(ni,4),[-2 -1 0 1],ni,ni));
assert(isequal(size(S),[69 69]),'JWPE:M1:Dimension', ...
    'Unexpected PF M1 JPattern size.');
end
