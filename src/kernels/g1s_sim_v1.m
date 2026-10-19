function out = g1s_sim_v1(ctx,theta,cfg,keepFull)
%G1S_SIM_V1 SCIENTIFIC ONLY: exact absolute-time G1, day 0--94.
theta=double(theta(:).'); assert(numel(theta)==4 && islogical(keepFull) && isscalar(keepFull), ...
    'G1S:Forward','Invalid forward request.');
z=g1s_map_v1('encode',theta,ctx.reactor,cfg);
p=struct('Kd',ctx.Kd,'kb',theta(1),'kG',theta(2),'tinf',theta(3),'Ai',theta(4));
s=ctx.settings; times=ctx.outputTimes(:); y=ctx.initial(:);
assert(ctx.startTime==0 && ctx.stopTime==94 && all(times<=94) && ...
    all(ctx.forcing.Time_d<=94),'G1S:Horizon','Phase III is reachable.');
breaks=unique([ctx.startTime;ctx.forcing.Time_d;s.switch_days(:);ctx.stopTime]);
if strcmp(ctx.reactor,'CS'), breaks=unique([breaks;ctx.auditTimes;times]); end
breaks=breaks(breaks>=0 & breaks<=94);
state=nan(numel(times),numel(y)); Cout=nan(size(times)); phase=zeros(size(times));
if keepFull, segments=cell(numel(breaks)-1,1); else, segments={}; end
minState=min(y); maxState=max(y); opts=odeset('RelTol',s.RelTol,'AbsTol',s.AbsTol);
if strcmp(ctx.reactor,'PF'), opts=odeset(opts,'JPattern',m1_pf_jpat_v1(s)); end
for k=1:numel(breaks)-1
    t0=breaks(k); t1=breaks(k+1); ph=1+(t0>=49)+(t0>=94);
    Cin=JWPE_next_zoh_influent(t0,ctx.forcing);
    if strcmp(ctx.reactor,'CS')
        N=s.tanks_in_series(ph); tm=s.mean_residence_time_h(ph)/24;
        assert(numel(y)==N,'G1S:State','Unexpected CS state dimension.');
        rhs=@(t,x)m1_cs_rhs_v1(t,x,Cin,N,tm,ctx.R,p,s);
    else
        Dax=s.axial_dispersion_m2_d(ph); v=s.axial_velocity_m_d(ph);
        rhs=@(t,x)m1_pf_rhs_v1(t,x,Cin,Dax,v,ctx.R,p,s);
    end
    sol=ode15s(rhs,[t0 t1],y,opts);
    assert(sol.x(end)>=t1-1e-10,'G1S:Solver','Incomplete solver segment.');
    y=sol.y(:,end); minState=min(minState,min(sol.y,[],'all')); maxState=max(maxState,max(sol.y,[],'all'));
    hit=find(times>t0+1e-10 & times<=t1+1e-10);
    if ~isempty(hit)
        values=deval(sol,times(hit)); state(hit,:)=values.'; Cout(hit)=values(end,:).'; phase(hit)=ph;
    end
    if keepFull
        segments{k}=struct('t0',t0,'t1',t1,'phase',ph,'Cin',Cin,'sol',sol);
    end
end
assert(all(isfinite(state),'all') && all(isfinite(Cout)) && all(phase<=2) && ...
    all(phase>0) && minState>=-2*s.AbsTol,'G1S:Forward','Invalid/missing/negative state.');
out=struct('reactor',ctx.reactor,'theta',theta,'z',z,'Kd',ctx.Kd, ...
    'times',times,'Cout',Cout,'states',state,'phase',phase, ...
    'terminal',y,'startState',ctx.initial,'startTime',0,'stopTime',94, ...
    'settings',s,'minState',minState,'maxState',maxState,'R',ctx.R, ...
    'fullPayload',keepFull);
if keepFull
    denseTimes=unique([(0:cfg.denseStep_d:94).';times]); denseC=nan(size(denseTimes)); denseC(1)=ctx.initial(end);
    for k=1:numel(segments)
        h=segments{k}; hit=denseTimes>h.t0+1e-10 & denseTimes<=h.t1+1e-10;
        values=deval(h.sol,denseTimes(hit)); denseC(hit)=values(end,:).';
    end
    A=arrayfun(@(t)JWPE_activity_G1(t,p),denseTimes);
    out.segments=segments;
    out.dense=table(denseTimes,denseC,A, ...
        s.XVSS_g_L*theta(1)*A/ctx.R,'VariableNames', ...
        {'Time_d','Cout_ug_L','Activity','keff_d_1'});
end
end
