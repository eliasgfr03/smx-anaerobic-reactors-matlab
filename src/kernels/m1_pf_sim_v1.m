function out = m1_pf_sim_v1(ctx,thetaM1,cfg)
%M1_PF_SIM_V1 Simulate the 69-state irreversible PF model through day 94.

assert(strcmp(ctx.reactor,'PF'),'JWPE:M1:Config','PF context required.');
map = m1_map_v1(thetaM1,cfg);
p = JWPE_parameter_struct(map.thetaEngine);
settings = ctx.settings;
R = 1+p.Kd*settings.XTSS_g_L;
ni = settings.node_count-2;
assert(ni==69,'JWPE:M1:Dimension','PF M1 requires 69 states.');
y = zeros(ni,1);
times = ctx.auditTimes_d(:);
assert(times(1)==0 && times(end)==94 && ~any(times>94), ...
    'JWPE:M1:Horizon','Invalid PF audit horizon.');
breaks = unique([0;ctx.forcingData.Time_d;settings.switch_days(:);94]);
breaks = breaks(breaks>=0 & breaks<=cfg.horizon.max_d);
state = zeros(numel(times),ni);
Cout = zeros(numel(times),1);
phaseAt = zeros(numel(times),1);
phaseAt(1) = 1;
segments = repmat(local_empty_segment(),numel(breaks)-1,1);
S = m1_pf_jpat_v1(settings);
opts = odeset('RelTol',settings.RelTol,'AbsTol',settings.AbsTol,'JPattern',S);
minState = 0;
maxState = 0;
tol = 1e-10;
for k=1:numel(breaks)-1
    t0 = breaks(k);
    t1 = breaks(k+1);
    phase = 1+(t0>=settings.switch_days(1))+(t0>=settings.switch_days(2));
    Cin = JWPE_next_zoh_influent(t0,ctx.forcingData);
    Dax = settings.axial_dispersion_m2_d(phase);
    v = settings.axial_velocity_m_d(phase);
    rhs = @(t,z)m1_pf_rhs_v1(t,z,Cin,Dax,v,R,p,settings);
    sol = ode15s(rhs,[t0 t1],y,opts);
    y = sol.y(:,end);
    minState = min(minState,min(sol.y,[],'all'));
    maxState = max(maxState,max(sol.y,[],'all'));
    segments(k) = struct('t0',t0,'t1',t1,'phase',phase,'N',ni, ...
        'Cin',Cin,'tm_d',NaN,'Dax',Dax,'v',v,'sol',sol);
    hit = find(times>t0+tol & times<=t1+tol);
    if ~isempty(hit)
        values = deval(sol,times(hit));
        state(hit,:) = values.';
        Cout(hit) = values(end,:).';
        phaseAt(hit) = phase;
    end
end
assert(all(isfinite(Cout)) && all(isfinite(state),'all') && all(phaseAt>0), ...
    'JWPE:M1:ForwardFailure','PF M1 returned incomplete or nonfinite values.');
out = struct('reactor','PF','model','M1','map',map,'p',p,'R',R, ...
    'times_d',times,'Cout_SMX',Cout,'SMX',state,'activeN', ...
    repmat(ni,numel(times),1),'phase',phaseAt,'segments',segments, ...
    'minSMX',minState,'maxSMX',maxState,'stateDimensionMax',ni, ...
    'stateDimensionIntegrated',ni);
end

function s = local_empty_segment()
s = struct('t0',NaN,'t1',NaN,'phase',NaN,'N',NaN,'Cin',NaN, ...
    'tm_d',NaN,'Dax',NaN,'v',NaN,'sol',struct());
end

