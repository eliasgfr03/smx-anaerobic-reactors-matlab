function cout = pf_dax_forward_v1(ctx,theta,f,cfg)
%PF_DAX_FORWARD_V1 Execute one nonbaseline full-history PF forward.

pf_dax_guard_v1('nonbaseline',f,cfg.f(cfg.baselineIndex));
assert(any(f==cfg.f) && isfinite(f) && f>=0, ...
    'JWPE:PFDAX:Coordinate','Unapproved scenario coordinate.');
scenario = ctx;
original = scenario.settings;
scenario.settings.axial_dispersion_m2_d = f*cfg.D0_m2_d;
unchangedBefore = rmfield(original,'axial_dispersion_m2_d');
unchangedAfter = rmfield(scenario.settings,'axial_dispersion_m2_d');
assert(isequaln(unchangedBefore,unchangedAfter) && ...
    isequal(scenario.settings.axial_velocity_m_d,cfg.u_m_d) && ...
    scenario.settings.length_m==cfg.length_m, ...
    'JWPE:PFDAX:Isolation','A non-dispersion setting changed.');
sim = p3v_sim_v1(scenario,theta,cfg);
assert(isequal(sim.times_d,ctx.fullTimes_d) && ...
    all(isfinite(sim.Cout_SMX)),'JWPE:PFDAX:Forward', ...
    'Full-history response is invalid.');
cout = sim.Cout_SMX(:);
end
