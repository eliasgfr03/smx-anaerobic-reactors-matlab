function c = jwpe_s04_conditional_ineq_v2(nuisance,profileIdx,fixedValue,cfgCore)
theta=jwpe_s04_full_theta_v2(profileIdx,fixedValue,nuisance);
c=jwpe_03b_native_ineq_v1(theta,cfgCore);
end
