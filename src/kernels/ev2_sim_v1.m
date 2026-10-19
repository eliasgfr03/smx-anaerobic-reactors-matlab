function out = ev2_sim_v1(ctx,theta,y0,cfg,stopTime)
%EV2_SIM_V1 USER-MANUAL ONLY. EV1 segment assembly, five-phase/A=1 delta.
assert(~ctx.responseAccessAllowed && strcmp(ctx.dataset,cfg.dataset) && ...
    stopTime>=49 && stopTime<=182,'JWPE:EV2:Isolation','Invalid scientific context.');
map=m1_map_v1(theta,cfg); p=JWPE_parameter_struct(map.thetaEngine);
settings=ctx.settings; y=double(y0(:));
assert(numel(y)==69 && all(isfinite(y)),'JWPE:EV2:State','Invalid initial state.');
R=1+p.Kd*settings.XTSS_g_L;
times=unique([ctx.auditTimes_d(ctx.auditTimes_d<=stopTime);stopTime]);
breaks=unique([ctx.start_d;ctx.forcingData.Time_d;settings.switch_days(:);stopTime]);
breaks=breaks(breaks>=ctx.start_d & breaks<=stopTime);
states=NaN(numel(times),69); states(1,:)=y.';
minimum=min(y); maximum=max(y); rawTime=cell(numel(breaks)-1,1); rawState=rawTime;
opts=odeset('RelTol',settings.RelTol,'AbsTol',settings.AbsTol, ...
    'JPattern',m1_pf_jpat_v1(settings));
for k=1:numel(breaks)-1
    t0=breaks(k); t1=breaks(k+1); phase=ev2_phase_v1(t0,cfg);
    cin=JWPE_next_zoh_influent(t0,ctx.forcingData);
    dax=settings.axial_dispersion_m2_d(phase); velocity=settings.axial_velocity_m_d(phase);
    rhs=@(t,z)ev2_rhs_v1(t,z,cin,dax,velocity,R,p,settings);
    solution=ode15s(rhs,[t0 t1],y,opts);
    assert(abs(solution.x(end)-t1)<=1e-10,'JWPE:EV2:Solver','Incomplete solver interval.');
    rawTime{k}=solution.x; rawState{k}=solution.y;
    y=solution.y(:,end); minimum=min(minimum,min(solution.y,[],'all'));
    maximum=max(maximum,max(solution.y,[],'all'));
    hit=find(times>t0+1e-10 & times<=t1+1e-10);
    if ~isempty(hit), states(hit,:)=deval(solution,times(hit)).'; end
end
out=struct('reactor',ctx.reactor,'thetaM1',theta,'map',map,'R',R, ...
    'times_d',times,'SMX',states,'Cout_SMX',states(:,end),'minSMX',minimum, ...
    'maxSMX',maximum,'solverTimes',{rawTime},'solverStates',{rawState}, ...
    'finite',all(isfinite(states),'all'),'solverPass',true, ...
    'negativePass',minimum>=-2*settings.AbsTol,'horizonEnd_d',stopTime);
% Raw output is returned before the caller persists and evaluates all guards.
end
