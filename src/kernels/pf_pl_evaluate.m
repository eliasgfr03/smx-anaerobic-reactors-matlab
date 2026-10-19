function out=pf_pl_evaluate(x,cfg,ctx,core,recheck)
%PF_PL_EVALUATE Same G1/combined likelihood and robust independent recheck.
theta=pf_pl_map(x,cfg);
out=jwpe_03b_evaluate_g1_v1(theta,ctx,core,recheck,recheck);
assert(~recheck || out.valid,'JWPE:Public:Budget','Invalid PF independent recheck.');
end
