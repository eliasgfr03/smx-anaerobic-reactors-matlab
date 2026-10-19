function out = ev1_sim_v1(ctx,thetaM1,y0,cfg,stopTime)
%EV1_SIM_V1 Thin external 69-state M1 simulator on absolute operational time.

assert(any(strcmp(ctx.reactor,cellstr(cfg.reactors))), ...
    'JWPE:EV1:Reactor','External response-free context required.');
assert(~ctx.responseAccessAllowed,'JWPE:EV1:Isolation', ...
    'Response-bearing context cannot enter the simulator.');
assert(stopTime>=ctx.start_d && stopTime<=ctx.end_d, ...
    'JWPE:EV1:Horizon','Invalid external simulation stop time.');
map = m1_map_v1(thetaM1,cfg);
p = JWPE_parameter_struct(map.thetaEngine);
settings = ctx.settings; n = settings.node_count-2;
y = double(y0(:));
assert(n==69 && numel(y)==n && all(isfinite(y)), ...
    'JWPE:EV1:Dimension','External initial state must contain 69 finite values.');
R = 1+p.Kd*settings.XTSS_g_L;
times = ctx.auditTimes_d(ctx.auditTimes_d<=stopTime);
times = unique([times;stopTime]);
breaks = unique([ctx.start_d;ctx.forcingData.Time_d; ...
    settings.switch_days(:);stopTime]);
breaks = breaks(breaks>=ctx.start_d & breaks<=stopTime);
state = NaN(numel(times),n); cout = NaN(numel(times),1);
phaseAt = zeros(numel(times),1); state(1,:) = y.'; cout(1) = y(end);
phaseAt(1) = local_phase(times(1),settings.switch_days);
S = m1_pf_jpat_v1(settings);
assert(isequal(size(S),[69 69]),'JWPE:EV1:Dimension','Wrong PF JPattern.');
opts = odeset('RelTol',settings.RelTol,'AbsTol',settings.AbsTol,'JPattern',S);
minimum = min(y); maximum = max(y); tolerance = 1e-10;
for k=1:numel(breaks)-1
    t0 = breaks(k); t1 = breaks(k+1);
    phase = local_phase(t0,settings.switch_days);
    cin = JWPE_next_zoh_influent(t0,ctx.forcingData);
    dax = settings.axial_dispersion_m2_d(phase);
    velocity = settings.axial_velocity_m_d(phase);
    rhs = @(t,z)m1_pf_rhs_v1(t,z,cin,dax,velocity,R,p,settings);
    solution = ode15s(rhs,[t0 t1],y,opts);
    y = solution.y(:,end);
    minimum = min(minimum,min(solution.y,[],'all'));
    maximum = max(maximum,max(solution.y,[],'all'));
    hit = find(times>t0+tolerance & times<=t1+tolerance);
    if ~isempty(hit)
        values = deval(solution,times(hit));
        state(hit,:) = values.'; cout(hit) = values(end,:).';
        phaseAt(hit) = phase;
    end
end
assert(all(isfinite(cout)) && all(isfinite(state),'all') && ...
    all(phaseAt>0),'JWPE:EV1:ForwardFailure', ...
    'External M1 simulation returned incomplete/nonfinite values.');
assert(minimum>=-2*settings.AbsTol,'JWPE:EV1:ForwardFailure', ...
    'Negative state exceeds source numerical tolerance.');
out = struct('reactor',ctx.reactor,'thetaM1',thetaM1,'map',map,'p',p, ...
    'R',R,'times_d',times,'Cout_SMX',cout,'SMX',state,'phase',phaseAt, ...
    'minSMX',minimum,'maxSMX',maximum,'stateDimensionIntegrated',n, ...
    'horizonStart_d',ctx.start_d,'horizonEnd_d',stopTime);
end

function phase = local_phase(time,switches)
phase = 1+(time>=switches(1))+(time>=switches(2))+(time>=switches(3));
end
