function out = ofl_sim_v1(ctx,kb,cfg)
%OFL_SIM_V1 SCIENTIFIC ONLY. Source event algebra, saved full-state segments.
assert(isscalar(kb) && isfinite(kb) && kb>=0 && ...
    kb<=cfg.kb_support.(ctx.reactor)(2),'OFL:Support','kb outside support.');
s = ctx.settings; times = ctx.outputTimes(:); y = ctx.initial(:);
assert(all(times>ctx.startTime) && times(end)==ctx.stopTime && ...
    all(ctx.forcing.Time_d<=ctx.stopTime),'OFL:Horizon','Invalid integration horizon.');
breaks = unique([ctx.startTime;ctx.forcing.Time_d;s.switch_days(:);ctx.stopTime]);
% CS source includes audit times as events; PF source does not.
if strcmp(ctx.reactor,'CS'), breaks = unique([breaks;ctx.auditTimes;times]); end
breaks = breaks(breaks>=ctx.startTime & breaks<=ctx.stopTime);
nMax = numel(y);
state = nan(numel(times),nMax); Cout = nan(size(times)); phase = zeros(size(times));
segments = cell(numel(breaks)-1,1);
minState = min(y); maxState = max(y);
opts = odeset('RelTol',s.RelTol,'AbsTol',s.AbsTol);
if strcmp(ctx.reactor,'PF'), opts=odeset(opts,'JPattern',m1_pf_jpat_v1(s)); end
for k=1:numel(breaks)-1
    t0=breaks(k); t1=breaks(k+1);
    ph=1+(t0>=49)+(t0>=94);
    h=struct('phase',ph,'N',numel(y),'Cin',JWPE_next_zoh_influent(t0,ctx.forcing), ...
        'tm_d',NaN,'Dax',NaN,'v',NaN);
    if strcmp(ctx.reactor,'CS')
        assert(numel(y)==s.tanks_in_series(ph),'OFL:State','CS full-state dimension.');
        h.tm_d=s.mean_residence_time_h(ph)/24;
    else
        h.Dax=s.axial_dispersion_m2_d(ph); h.v=s.axial_velocity_m_d(ph);
    end
    sol=ode15s(@(t,z)ofl_rhs_v1(t,z,ctx,kb,h),[t0 t1],y,opts);
    assert(sol.x(end)>=t1-1e-10,'OFL:Solver','Incomplete solver segment.');
    y=sol.y(:,end); minState=min(minState,min(sol.y,[],'all'));
    maxState=max(maxState,max(sol.y,[],'all'));
    h.t0=t0; h.t1=t1; h.sol=sol; segments{k}=h;
    hit=find(times>t0+1e-10 & times<=t1+1e-10);
    if ~isempty(hit)
        values=deval(sol,times(hit)); state(hit,:)=values.';
        Cout(hit)=values(end,:).'; phase(hit)=ph;
    end
end
assert(all(isfinite(state),'all') && all(isfinite(Cout)) && all(phase>0) && ...
    minState>=-2*s.AbsTol,'OFL:Forward','Nonfinite, missing or negative state.');
denseTimes=unique([ctx.startTime:cfg.denseStep_d:ctx.stopTime,times.']).';
denseC=nan(size(denseTimes)); denseC(1)=ctx.initial(end);
for k=1:numel(segments)
    h=segments{k}; hit=denseTimes>h.t0+1e-10 & denseTimes<=h.t1+1e-10;
    v=deval(h.sol,denseTimes(hit)); denseC(hit)=v(end,:).';
end
out=struct();
out.reactor=ctx.reactor; out.kb=kb; out.Kd=ctx.Kd; out.A=ctx.A;
out.times=times; out.Cout=Cout; out.states=state; out.phase=phase;
out.segments=segments; out.terminal=y; out.startState=ctx.initial;
out.startTime=ctx.startTime; out.stopTime=ctx.stopTime; out.settings=s;
out.minState=minState; out.maxState=maxState; out.R=ctx.R;
out.dense=table(denseTimes,denseC,'VariableNames',{'Time_d','Cout_ug_L'});
end
