function e = jwpe_fixed_evaluate_v1(ctx,theta,cfg,phase,onSigma)
%JWPE_FIXED_EVALUATE_V1 Enforce fixed Kd then reuse the qualified evaluator.
assert(theta(1)==0.020 && cfg.fixedKd==0.020);
e=jwpe_m1_pl_evaluate(ctx,theta,cfg,phase,onSigma);
end
