function theta = jwpe_fixed_theta_v1(u,cfg)
%JWPE_FIXED_THETA_V1 Decode nuisance coordinates without unfixing Kd.
u=double(u(:).');assert(numel(u)==numel(cfg.freeIndices) && all(isfinite(u)));
assert(all(u>=0 & u<=1));
theta=double(cfg.baseTheta(:).');
theta(cfg.freeIndices)=cfg.lower+u.*(cfg.upper-cfg.lower);
theta(1)=cfg.fixedKd;theta(cfg.fixedIndex)=cfg.fixedValue;
assert(theta(1)==0.020);
end
